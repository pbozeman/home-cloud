variable "zone_id" {
  type = string
}

variable "cloudkey_ip" {
  type = string
}

variable "pve_nodes" {
  type = map(object({
    ip = string
  }))
}
