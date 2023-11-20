variable "zone_id" {
  type = string
}

variable "hosts" {
  type = map(object({
    ip = string
  }))
}

variable "round_robin" {
  type = map(list(string))
}
