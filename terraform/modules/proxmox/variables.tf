variable "pve_nodes" {
  type = map(object({
    ip = string
  }))
}

variable "local_dns_ip" {
  type = string
}

variable "proxmox_ssh_privkey" {
  type = string
}

variable "proxmox_ssh_pubkey" {
  type = string
}

variable "proxmox_password" {
  type = string
}

variable "ssh_pubkeys" {
  type = list(string)
}
