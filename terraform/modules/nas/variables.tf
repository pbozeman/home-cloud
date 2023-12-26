variable "vm_ids" {
  type = map(string)
}

variable "nas_nodes" {
  type = map(object({
    ip      = string
    host_id = string

    shares = map(object({
      quota         = optional(string, "none")
      compression   = optional(string, "on")
      auto-snapshot = optional(bool, false)
      atime         = optional(string, "off")
      nfs           = optional(string, "off")
      backup        = optional(bool, false)
      smb-name      = optional(string)
    }))
  }))
}

variable "kopia" {
  type = object({
    b2_bucket          = string
    b2_key_id          = string
    b2_application_key = string
    repo_password      = string
  })
  sensitive = true
}

variable "tailscaleKey" {
  type      = string
  sensitive = true
}
