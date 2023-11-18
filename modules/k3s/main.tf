# FIXME: these are not currently re-triggering on vm recreation (although,
# if triggered they do wait for the vm models to complete)

locals {
  init_nodes = { for k, v in var.k3s_nodes : k => v if v.cluster_init == true }
  first_node = keys(local.init_nodes)[0]

  subsequent_nodes = { for k, v in var.k3s_nodes : k => v if v.cluster_init == false }
}
module "first" {
  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host = "root@${local.first_node}"

  flake = "./${path.module}/nixos#first"

  arguments = [
    "--build-host", "root@${local.first_node}"
  ]

  ssh_options = "-o StrictHostKeyChecking=accept-new"
}

module "subsequent" {
  for_each = local.subsequent_nodes

  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host = "root@${each.key}"

  flake = "./${path.module}/nixos#subsequent"

  arguments = [
    "--build-host", "root@${each.key}"
  ]

  ssh_options = "-o StrictHostKeyChecking=accept-new"
}
