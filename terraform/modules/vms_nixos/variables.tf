variable "pve_nodes" {
  type = map(object({
    ip = string
  }))
}

variable "ubuntu_vm_template_ids" {
  type = map(number)
}

variable "nixos_vms" {
  type = map(object({
    pve_node              = string
    ip                    = string
    gateway               = string
    cores                 = number
    memory                = number
    host_id               = string
    data_disk_size        = number
    username              = string
    pci_passthrough_addrs = optional(list(string))
    zfs_disks             = optional(map(string), {})

    danger_wipe_zfs_disks_and_initialize = optional(bool, false)
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
