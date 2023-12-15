locals {
  cloudkey_host = {
    cloudkey = {
      ip = var.cloudkey_01_ip
    }
  }

  host_dns = merge(
    local.cloudkey_host,
    var.pve_nodes,
    var.nixos_dev_vms,
    var.nixos_nas_vms,
    var.nixos_k3s_vms,
    var.k3s_services,
  )

  round_robin_dns = {
    pve = [for node in var.pve_nodes : node.ip]
    k3s = [for node in var.nixos_k3s_vms : node.ip]
  }
}

# DNS name for the physical servers and appliances
module "cloudflare" {
  source = "./modules/cloudflare"

  zone_id = var.cloudflare_zone_id

  hosts       = local.host_dns
  round_robin = local.round_robin_dns
}

# The core unifi network
module "unifi" {
  source = "./modules/unifi"

  domain_name = var.domain_name

  local_dns_ip = var.local_dns_ip

  switches = var.unifi_switches
  clients  = var.unifi_clients

  k3s_ingress_ip = var.k3s_ingress_ip

  trusted_vlan       = 20
  trusted_ssid       = var.trusted_ssid
  trusted_passphrase = var.trusted_passphrase

  kids_vlan       = 30
  kids_ssid       = var.kids_ssid
  kids_passphrase = var.kids_passphrase

  iot_vlan       = 40
  iot_ssid       = var.iot_ssid
  iot_passphrase = var.iot_passphrase

  guest_vlan       = 50
  guest_ssid       = var.guest_ssid
  guest_passphrase = var.guest_passphrase
}

module "proxmox" {
  source = "./modules/proxmox"

  pve_nodes = var.pve_nodes

  local_dns_ip = var.local_dns_ip

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password    = var.proxmox_password
  proxmox_ssh_privkey = var.proxmox_ssh_privkey
  proxmox_ssh_pubkey  = var.proxmox_ssh_pubkey

  dns_ids = module.cloudflare.ids
}

module "vms_ubuntu" {
  source = "./modules/vms_ubuntu"

  pve_nodes = var.pve_nodes

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}

# dev vms
module "vms_dev" {
  source = "./modules/vms_nixos"

  pve_nodes = var.pve_nodes

  ubuntu_vm_template_ids = module.vms_ubuntu.ubuntu_vm_template_ids

  nixos_vms = var.nixos_dev_vms

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}

# nas vms
module "vms_nas" {
  source = "./modules/vms_nixos"

  pve_nodes = var.pve_nodes

  ubuntu_vm_template_ids = module.vms_ubuntu.ubuntu_vm_template_ids

  nixos_vms = var.nixos_nas_vms

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}

module "nas" {
  source    = "./modules/nas"
  vm_ids    = module.vms_nas.ids
  nas_nodes = var.nixos_nas_vms
}

# k3s vms
module "vms_k3s" {
  source = "./modules/vms_nixos"

  pve_nodes = var.pve_nodes

  ubuntu_vm_template_ids = module.vms_ubuntu.ubuntu_vm_template_ids

  nixos_vms = var.nixos_k3s_vms

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}

module "k3s" {
  source = "./modules/k3s"
  vm_ids = module.vms_k3s.ids

  k3s_nodes = var.nixos_k3s_vms
  k3s_name  = "k3s.${var.domain_name}"
}
