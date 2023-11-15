# DNS name for the physical servers and appliances
module "cloudflare-physical" {
  source = "./cloudflare"

  zone_id = var.cloudflare_zone_id

  cloudkey_ip = var.cloudkey_01_ip

  pve_nodes = var.pve_nodes
}

# The core unifi network
module "unifi" {
  source = "./unifi"

  domain_name = var.domain_name

  local_dns_ip = var.local_dns_ip

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
  source = "./proxmox"

  pve_nodes = var.pve_nodes

  local_dns_ip = var.local_dns_ip

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password    = var.proxmox_password
  proxmox_ssh_privkey = var.proxmox_ssh_privkey
  proxmox_ssh_pubkey  = var.proxmox_ssh_pubkey
}

module "vms" {
  source = "./vms"

  pve_nodes = var.pve_nodes

  nixos_vms = var.nixos_vms

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}
