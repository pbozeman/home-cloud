resource "proxmox_virtual_environment_vm" "ubuntu_dev" {
  node_name = "pve-01"

  name    = "ubuntu-dev"
  on_boot = false
  started = false

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_vm_template["pve-01"].vm_id
  }

  cpu {
    type  = "host"
    cores = 4
  }

  memory {
    dedicated = 8192
  }

  lifecycle {
    ignore_changes = [
      started
    ]
  }
}
