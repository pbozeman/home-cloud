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

    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor[each.value.pve_node].id

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
      clone
    ]
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
