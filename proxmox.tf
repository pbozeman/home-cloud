# manual steps:
#   enable Snippet storage on local

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
  tmp_dir  = "/var/tmp"
}

resource "proxmox_virtual_environment_dns" "pve_01" {
  domain    = data.proxmox_virtual_environment_dns.pve_01.domain
  node_name = data.proxmox_virtual_environment_dns.pve_01.node_name

  servers = [
    var.local_dns_ip,
  ]
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve-01"

  source_file {
    # 22.04 LTS
    path = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  }
}

# by using the vendor file we can still use the the nicer user_account
# provider settings rather than having to fully customize the yaml file
resource "proxmox_virtual_environment_file" "cloud_config_vendor" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve-01"

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

# the disk for bpg/terraform templated vms do not get converted to "base" disks
# and can't be used as the base of a linked clone.
resource "proxmox_virtual_environment_vm" "ubuntu_vm_template" {
  node_name = "pve-01"
  vm_id     = 9000

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

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    size         = 64
  }

  initialization {
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_config_vendor.id

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
      host     = var.pve_01_ip
    }
    inline = ["qm template ${self.vm_id} --disk virtio0"]
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_dev" {
  node_name = "pve-01"
  vm_id     = 8000

  name    = "ubuntu-dev"
  on_boot = false
  started = false

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_vm_template.vm_id
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

resource "terraform_data" "nixos_pve_restored" {
  provisioner "file" {
    source      = "/nix/store/7byrjn28mcynk55xv0zwpw95a70ay6x2-proxmox-nixos-23.11.20230825.5690c42/vzdump-qemu-nixos-23.11.20230825.5690c42.vma.zst"
    destination = "/var/lib/vz/dump/vzdump-qemu-nixos-23.11.20230825.5690c42.vma.zst"

    connection {
      type     = "ssh"
      host     = var.pve_01_ip
      user     = "root"
      password = var.proxmox_password
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.pve_01_ip
    }
    inline = ["qm create 9001 --force true --template true --name nixos-pve-template --archive /var/lib/vz/dump/vzdump-qemu-nixos-23.11.20230825.5690c42.vma.zst"]
  }
}

resource "proxmox_virtual_environment_vm" "nixos_pve" {
  node_name = "pve-01"
  vm_id     = 8001

  name    = "nixos-pve"
  on_boot = true
  started = true

  clone {
    vm_id = 9001
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = 16384
  }

  cpu {
    # needed for nested virtualization
    type  = "host"
    cores = 6
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    iothread     = true
    size         = 64
  }

  # packages and users are managed inside nix
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  depends_on = [
    terraform_data.nixos_pve_restored
  ]
}

data "proxmox_virtual_environment_dns" "pve_01" {
  node_name = "pve-01"
}
