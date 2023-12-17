variable "vm_ids" {
  type = map(string)
}

variable "nas_nodes" {
  type = map(object({
    ip      = string
    host_id = string
  }))
}
