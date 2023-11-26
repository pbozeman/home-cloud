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

# FIXME: it was a bad idea to merge all the vms together.
# Specifically, the dev vm needs to be kept searpate so that low level
# changes can be made to the vms without recreating the dev vm.
# Undo this generalization.
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
    vm_id = proxmox_virtual_environment_vm.ubuntu_vm_template[each.value.pve_node].vm_id
  }

  cpu {
    type  = "host"
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
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
    ]
    prevent_destroy = true
  }

  # multi disk management with this provider is very buggy. Hence the manual
  # creation here, and the ignore above.
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
  provisioner "local-exec" {
    command = <<EOF
      set -e
      cd ${path.module}/nixos
      nix run github:numtide/nixos-anywhere -- --flake .#template ${each.value.username}@${each.value.ip} --build-on-remote
    EOF
  }
}

output "version" {
  value = { for k, v in proxmox_virtual_environment_vm.nixos_vms : k => sha1(join("", sort(v.mac_addresses))) }
}
