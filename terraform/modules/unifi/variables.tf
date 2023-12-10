variable "domain_name" {
  type = string
}

variable "local_dns_ip" {
  type = string
}

variable "trusted_vlan" {
  type = number
}

variable "kids_vlan" {
  type = number
}

variable "iot_vlan" {
  type = number
}

variable "guest_vlan" {
  type = number
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

variable "clients" {
  type = map(object({
    mac               = string
    ip                = string
    allow_internet    = bool
    allow_k3s_ingress = bool
  }))
}

variable "k3s_ingress_ip" {
  type = string
}
