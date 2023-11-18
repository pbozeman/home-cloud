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
    cores = 4
  }

  memory {
    dedicated = 12288
  }

  initialization {
    datastore_id = "local"

    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor[each.value.pve_node].id

    user_account {
      username = var.nixos_username
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
}

# install nix, and reboot the node if it failed, as a reboot will return
# to debian on a failed build
resource "null_resource" "nixos_vms_install" {
  for_each = var.nixos_vms

  provisioner "local-exec" {
    # i'm sorry.
    command = <<EOF
      set -e
      cd ${path.module}/nixos
      nix run github:numtide/nixos-anywhere -- --flake .#template ${var.nixos_username}@${[for ip in flatten(proxmox_virtual_environment_vm.nixos_vms[each.key].ipv4_addresses) : ip if !startswith(ip, "127.")][0]} --build-on-remote || (ssh root@#{each.value.pve_node} 'qm reset ${proxmox_virtual_environment_vm.nixos_vms[each.key].vm_id} && false')
    EOF
  }

  # FIXME: trigger on vm rebild
}
