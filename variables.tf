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

variable "clients_ssid" {
  type = string
}

variable "clients_passphrase" {
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

variable "pve_01_mac" {
  type = string
}

variable "pve_01_ip" {
  type = string
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

variable "ubuntu_username" {
  type = string
}

variable "ubuntu_password" {
  type = string
}
