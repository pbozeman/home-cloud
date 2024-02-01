variable "pve_nodes" {
  type = map(object({
    ip = string
  }))
}

variable "pve_iommu_nodes" {
  type = map(object({
    iommu_key = string
    blacklist = list(string)
    vfio_ids  = string
  }))
  default = {}
}

variable "local_dns_ip" {
  type = string
}

variable "proxmox_ssh_privkey" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_pubkey" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_prometheus_username" {
  type = string
}

variable "proxmox_prometheus_password" {
  type      = string
  sensitive = true
}

variable "ssh_pubkeys" {
  type = list(string)
}

variable "dns_ids" {
  type = list(string)
}
