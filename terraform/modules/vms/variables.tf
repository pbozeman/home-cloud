variable "pve_nodes" {
  type = map(object({
    ip = string
  }))
}

variable "nixos_vms" {
  type = map(object({
    pve_node       = string
    ip             = string
    gateway        = string
    cores          = number
    memory         = number
    data_disk_size = number
    username       = string
  }))
}

variable "proxmox_password" {
  type = string
}

variable "ssh_pubkeys" {
  type = list(string)
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
