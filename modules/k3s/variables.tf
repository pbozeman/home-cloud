variable "vms_dependency" {
  type = string
}

variable "k3s_name" {
  type = string
}

variable "k3s_nodes" {
  type = map(object({
    ip           = string
    cluster_init = bool
  }))

  validation {
    condition     = length({ for k, v in var.k3s_nodes : k => v if v.cluster_init == true }) == 1
    error_message = "There must be one and only one entry with cluster_init = true"
  }
}
