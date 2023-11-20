locals {
  init_nodes = { for k, v in var.k3s_nodes : k => v if v.cluster_init == true }
  first_node = keys(local.init_nodes)[0]

  subsequent_nodes = { for k, v in var.k3s_nodes : k => v if v.cluster_init == false }
}
module "first" {
  source = "github.com/pbozeman/terraform-nixos-ng/nixos"

  host = "root@${local.first_node}"

  flake = "./${path.module}/nixos#first"

  arguments = [
    "--build-host", "root@${local.first_node}"
  ]

  ssh_options = "-o StrictHostKeyChecking=no"

  trigger = var.triggers[local.first_node]
}

module "subsequent" {
  for_each = local.subsequent_nodes

  source = "github.com/pbozeman/terraform-nixos-ng/nixos"

  host = "root@${each.key}"

  flake = "./${path.module}/nixos#subsequent"

  arguments = [
    "--build-host", "root@${each.key}"
  ]

  ssh_options = "-o StrictHostKeyChecking=no"

  trigger = var.triggers[each.key]
}

resource "null_resource" "kubeconfig" {
  count = try(file("~/.kube/config"), "") == "" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      ssh root@${local.first_node} kubectl config view --raw | sed -e 's/127.0.0.1:6443/${var.k3s_name}:6443/' > ~/.kube/config
    EOF
  }
}
