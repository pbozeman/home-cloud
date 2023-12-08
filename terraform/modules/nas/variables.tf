variable "vm_ids" {
  type = list(number)
}

variable "nas_nodes" {
  type = map(object({
    ip = string
  }))
}
