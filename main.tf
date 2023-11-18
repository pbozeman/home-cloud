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
    var.nixos_k3s_vms
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
}

module "vms" {
  source = "./modules/vms"

  pve_nodes = var.pve_nodes

  nixos_vms = merge(var.nixos_dev_vms, var.nixos_k3s_vms)

  ssh_pubkeys = var.ssh_pubkeys

  proxmox_password = var.proxmox_password

  ubuntu_username = var.ubuntu_username
  ubuntu_password = var.ubuntu_password

  nixos_username = var.nixos_username
  nixos_password = var.nixos_password
}

module "k3s" {
  source         = "./modules/k3s"
  vms_dependency = module.vms.done
}
