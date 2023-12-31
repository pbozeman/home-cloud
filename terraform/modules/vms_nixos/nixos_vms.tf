locals {
  flake_path = "./${path.module}/nixos"
}

# TODO: consider moving this to the top of the heirarchy and
# using it form the pve nodes too. Testing/iterating from here for now.
resource "tls_private_key" "host_ssh_key" {
  for_each = toset(keys(var.nixos_vms))

  algorithm = "ED25519"
}

resource "proxmox_virtual_environment_file" "nixos_cloud_config_vendor" {
  for_each = var.nixos_vms

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.pve_node


  # this is actually applied to the original ubuntu vm prior to the
  # nixos-anywhere deploy, hence the need to install the agent.
  source_raw {
    data = <<EOF
      #cloud-config vendor
      package_upgrade: true
      package_reboot_if_required: true
      packages:
        - qemu-guest-agent

      ssh_keys:
        ed25519_private: "${replace(tls_private_key.host_ssh_key[each.key].private_key_openssh, "\n", "\\n")}"
        ed25519_public: "${trimspace(tls_private_key.host_ssh_key[each.key].public_key_openssh)}"

      ssh_deletekeys: false
    EOF

    # The teraform provider docs give a yaml file as an example.
    # However, Proxmox is actually quite picky and "yaml" doesn't work.
    # This must end in ".yml"
    file_name = "nixos-${each.key}-cloud-config-vendor.yml"
  }
}

# TODO: consider merging all the flakes
resource "local_file" "flake" {
  content = templatefile("${local.flake_path}/flake.tftpl", {
    nodes = var.nixos_vms
  })

  filename        = "${local.flake_path}/flake.nix"
  file_permission = "600"
}

resource "proxmox_virtual_environment_vm" "nixos_vms" {
  for_each = var.nixos_vms

  node_name = each.value.pve_node

  name    = each.key
  on_boot = true
  started = true

  agent {
    enabled = true
    timeout = "5m"
  }

  clone {
    vm_id = var.ubuntu_vm_template_ids[each.value.pve_node]
  }

  cpu {
    type  = "host"
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  dynamic "hostpci" {
    for_each = { for idx, addr in(each.value.pci_passthrough_addrs != null ? each.value.pci_passthrough_addrs : []) : tostring(idx) => addr }

    content {
      id     = hostpci.value
      device = "hostpci${hostpci.key}"
    }
  }

  initialization {
    datastore_id = "local"

    vendor_data_file_id = proxmox_virtual_environment_file.nixos_cloud_config_vendor[each.key].id

    user_account {
      username = each.value.username
      password = var.nixos_password
      keys     = var.ssh_pubkeys
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = each.value.gateway
      }
    }
  }

  lifecycle {
    ignore_changes = [
      clone,
      disk,
      started,
    ]
    prevent_destroy = true
  }

  # multi disk management with this provider is very buggy. Hence the manual
  # creation here, and the ignore above.
  #
  # TODO: add iothread
  provisioner "remote-exec" {
    inline = [<<EOF
      if [ "${each.value.data_disk_size}" -gt 0 ]; then
        ssh root@${each.value.pve_node} \
        "qm set ${self.vm_id} --virtio1 local-zfs:${each.value.data_disk_size},format=raw"
      fi
      EOF
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.value.pve_node
    }
  }

  # keeping this in this resource rather than a separate resource so that
  # it will always trigger on a create, but not on update. splitting it out
  # has the advantage that it can reuse the vm if it failed. However, it
  # won't rerun if the vm is trainted and re-created.
  #
  # flake.nix is instantiated from a template, but nixos-anywhere requires
  # that it be checked into git in order to make it part of the build. It is
  # ok if it is dirty.  We don't want to check in the actual flake because
  # it could contain secrets. It's in gitignore, but assume-unchanged is
  # also necessary to keep it from showing up in diffs.
  provisioner "local-exec" {
    command = <<EOF
      set -e
      trap 'git update-index --assume-unchanged flake.nix' EXIT
      cd ${path.module}/nixos
      git update-index --no-assume-unchanged flake.nix
      nix run github:numtide/nixos-anywhere -- --flake .#${each.key} ${each.value.username}@${each.value.ip} --build-on-remote
    EOF
  }

  # Create zfspool, if requested.
  # I tried to do this inside the nix files, but didn't seem to have access
  # to the necessary utils in the postInstall hooks.
  #
  # NOTE: the false version of the branch below still executes a command
  # on the new vm. This provides a check the vm is ready.
  #
  # TODO: add keys via terraform so that we don't have to rely on the user's
  # private key
  #
  provisioner "remote-exec" {
    inline = [<<EOF
      %{if each.value.danger_wipe_zfs_disks_and_initialize}
        zpool create -o ashift=12 storage raidz ${join(" ", each.value.zfs_disks)}
      %{else}
        true
      %{endif}
    EOF
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = each.value.ip
    }
  }

  depends_on = [
    local_file.flake
  ]
}

output "ids" {
  value = { for k, v in proxmox_virtual_environment_vm.nixos_vms : k => v.id }
}
