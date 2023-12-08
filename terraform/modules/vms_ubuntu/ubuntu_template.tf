resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  for_each = var.pve_nodes

  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key

  source_file {
    # 22.04 LTS
    path = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  }
}

# this modifies cloud-init to install the qemu guest tools into the vm.
#
# by using the vendor file we can still use the the nicer user_account
# provider settings rather than having to fully customize the yaml file
resource "proxmox_virtual_environment_file" "cloud_config_vendor" {
  for_each = var.pve_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.key

  source_raw {
    data = <<EOF
      #cloud-config vendor
      package_upgrade: true
      package_reboot_if_required: true
      packages:
        - qemu-guest-agent
    EOF

    # The teraform provider docs give a yaml file as an example.
    # However, Proxmox is actually quite picky and "yaml" doesn't work.
    # This must end in ".yml"
    file_name = "cloud-config-vendor.yml"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm_template" {
  for_each = var.pve_nodes

  node_name = each.key

  name     = "ubuntu-vm-template"
  on_boot  = false
  started  = false
  template = true

  agent {
    enabled = true
  }

  cpu {
    # needed for nested virtualization
    type = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image[each.key].id
    interface    = "virtio0"
    iothread     = true
    size         = 64
  }

  initialization {
    datastore_id        = "local"
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor[each.key].id

    user_account {
      username = var.ubuntu_username
      password = var.ubuntu_password
      keys     = var.ssh_pubkeys
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  # The provider does not convert the disk to a base disk with tempate=true.
  # This is a work around to do it imperatively.
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.value.ip
    }
    inline = ["qm template ${self.vm_id} --disk virtio0"]
  }
}

output "ubuntu_vm_template_ids" {
  value = { for key, value in var.pve_nodes : key => proxmox_virtual_environment_vm.ubuntu_vm_template[key].vm_id }
}
