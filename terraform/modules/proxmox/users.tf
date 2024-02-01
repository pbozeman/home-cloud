resource "proxmox_virtual_environment_user" "prometheus" {
  acl {
    path      = "/"
    propagate = true
    role_id   = data.proxmox_virtual_environment_role.operations_role.role_id
  }

  comment  = "Managed by Terraform"
  password = var.proxmox_prometheus_password
  user_id  = var.proxmox_prometheus_username
}

data "proxmox_virtual_environment_role" "operations_role" {
  role_id = "PVEAuditor"
}
