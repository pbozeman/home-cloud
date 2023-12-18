variable "vm_ids" {
  type = map(string)
}

variable "nas_nodes" {
  type = map(object({
    ip      = string
    host_id = string

    shares = map(object({
      quota         = string
      compression   = optional(string, "on")
      auto-snapshot = optional(bool, false)
      atime         = optional(string, "off")
    }))
  }))
}
