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

# the disk for bpg/terraform templated vms do not get converted to "base" disksprox
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

resource "null_resource" "build_dir" {
  provisioner "local-exec" {
    command = "mkdir -p .build"
  }
}

resource "null_resource" "local_nixos_vma" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p .build/nixos-template
      cd .build/nixos-template
      nix build ../../nixos-template#proxmox-template
      cat result/nix-support/hydra-build-products | cut -f 3 -d' ' > vma_path
    EOF
  }

  triggers = {
    nix    = "${sha1(file("nixos-template/flake.nix"))}"
    config = "${sha1(file("nixos-template/configuration.nix"))}"
  }

  depends_on = [
    null_resource.build_dir
  ]
}

data "local_file" "nixos_vma" {
  filename = ".build/nixos-template/vma_path"

  depends_on = [
    null_resource.local_nixos_vma
  ]
}

resource "null_resource" "proxmox_nixos_vma" {
  provisioner "file" {
    source      = trimspace(data.local_file.nixos_vma.content)
    destination = "/var/lib/vz/dump/${basename(trimspace(data.local_file.nixos_vma.content))}"

    connection {
      type     = "ssh"
      host     = var.pve_01_ip
      user     = "root"
      password = var.proxmox_password
    }
  }

  triggers = {
    local_vma_id = data.local_file.nixos_vma.id
  }
}

resource "null_resource" "ssh_pubkeys" {
  triggers = {
    ssh_pubkeys = join("", var.ssh_pubkeys)
  }
}

resource "null_resource" "nixos_temp_template" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.pve_01_ip
    }
    inline = ["qm create 9999 --force true --template true --name nixos-temp-template --archive /var/lib/vz/dump/${basename(trimspace(data.local_file.nixos_vma.content))}"]
  }

  triggers = {
    vma_id      = null_resource.proxmox_nixos_vma.id
    ssh_pubkeys = null_resource.ssh_pubkeys.id
  }
}

resource "random_password" "nixos_password" {
  length = 16
}

resource "proxmox_virtual_environment_vm" "nixos_template" {
  node_name = "pve-01"
  name      = "nixos-template"
  vm_id     = 9001
  template  = true

  agent {
    enabled = true
  }

  clone {
    vm_id = 9999
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    iothread     = false
    size         = 16
  }

  initialization {
    user_account {
      username = "nixos"
      password = random_password.nixos_password.result
      keys     = var.ssh_pubkeys
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # The provider does not convert the disk to a base disk with tempate=true.
  # This is a work around to do it imperatively.
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.pve_01_ip
    }
    inline = [
      "qm template ${self.vm_id} --disk virtio0",
      "qm destroy 9999"
    ]
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.nixos_temp_template.id,
    ]
    # the provider wants to keep re-reading things like ip addr etc,
    # so make it all stop. Nothing will actually be changing remotely.
    ignore_changes = all
  }

  depends_on = [
    null_resource.nixos_temp_template
  ]
}

resource "proxmox_virtual_environment_vm" "nixos_pve" {
  node_name = "pve-01"
  vm_id     = 8001

  name    = "nixos-pve"
  on_boot = true
  started = true

  clone {
    vm_id = proxmox_virtual_environment_vm.nixos_template.vm_id
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

  lifecycle {
    prevent_destroy = true
  }
}

data "proxmox_virtual_environment_dns" "pve_01" {
  node_name = "pve-01"
}
