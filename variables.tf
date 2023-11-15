variable "ssh_pubkeys" {
  type = list(string)
}

variable "domain_name" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "unifi_username" {
  type = string
}

variable "unifi_password" {
  type = string
}

variable "unifi_api_url" {
  type = string
}

variable "trusted_ssid" {
  type = string
}

variable "trusted_passphrase" {
  type = string
}

variable "iot_ssid" {
  type = string
}

variable "iot_passphrase" {
  type = string
}

variable "kids_ssid" {
  type = string
}

variable "kids_passphrase" {
  type = string
}

variable "guest_ssid" {
  type = string
}

variable "guest_passphrase" {
  type = string
}

variable "cloudkey_01_ip" {
  type = string
}

variable "local_dns_ip" {
  type = string
}

variable "pve_nodes" {
  type = map(object({
    ip  = string
    mac = string
  }))
}

variable "nixos_vms" {
  type = map(object({
    pve_node = string
    ip       = string
    gateway  = string
  }))
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type = string
}

variable "proxmox_ssh_privkey" {
  type = string
}

variable "proxmox_ssh_pubkey" {
  type = string
}

variable "ubuntu_username" {
  type = string
}

variable "ubuntu_password" {
  type = string
}

variable "nixos_username" {
  type = string
}

variable "nixos_password" {
  type = string
}
