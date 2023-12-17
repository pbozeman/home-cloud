# FIXME: the variables evolved without knowing about
# defaults, optional(<type>), etc. And, they kept getting
# added with minimal/no rethiniking of their sturcture
# as funciontality was needed. Step back and refactor
# with a less total n00b understaning of terraform and
# the overall configuration needs. Ditto for submodules.

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
  type      = string
  sensitive = true
}

variable "unifi_api_url" {
  type = string
}

variable "trusted_ssid" {
  type = string
}

variable "trusted_passphrase" {
  type      = string
  sensitive = true
}

variable "iot_ssid" {
  type = string
}

variable "iot_passphrase" {
  type      = string
  sensitive = true
}

variable "kids_ssid" {
  type = string
}

variable "kids_passphrase" {
  type      = string
  sensitive = true
}

variable "guest_ssid" {
  type = string
}

variable "guest_passphrase" {
  type      = string
  sensitive = true
}

variable "unifi_switches" {
  type = map(object({
    mac  = string
    name = string
    port_overrides = list(object({
      number       = number
      name         = string
      port_profile = string
    }))
  }))
}

# FIXME: the allow_* are actually only used on the IoT vlan. It is misleanding
# to mix the iot and regular clients
variable "unifi_clients" {
  type = map(object({
    mac               = string
    name              = string
    ip                = string
    allow_internet    = bool
    allow_k3s_ingress = bool
  }))
}

variable "cloudkey_01_ip" {
  type = string
}

variable "local_dns_ip" {
  type = string
}

variable "k3s_ingress_ip" {
  type = string
}

variable "k3s_services" {
  type = map(object({
    ip = string
  }))
}

variable "pve_nodes" {
  type = map(object({
    ip  = string
    mac = string
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

variable "nixos_dev_vms" {
  type = map(object({
    pve_node       = string
    ip             = string
    gateway        = string
    cores          = number
    memory         = number
    host_id        = string
    data_disk_size = number
    username       = string
  }))
}

variable "nixos_nas_vms" {
  type = map(object({
    pve_node              = string
    ip                    = string
    gateway               = string
    cores                 = number
    memory                = number
    host_id               = string
    data_disk_size        = number
    username              = string
    pci_passthrough_addrs = list(string)
  }))
}

variable "nixos_k3s_vms" {
  type = map(object({
    pve_node       = string
    ip             = string
    gateway        = string
    cores          = number
    memory         = number
    host_id        = string
    username       = string
    data_disk_size = number
    cluster_init   = bool
  }))
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_privkey" {
  type      = string
  sensitive = true
}

variable "proxmox_ssh_pubkey" {
  type = string
}

variable "ubuntu_username" {
  type = string
}

variable "ubuntu_password" {
  type      = string
  sensitive = true
}

variable "nixos_username" {
  type = string
}

variable "nixos_password" {
  type      = string
  sensitive = true
}
