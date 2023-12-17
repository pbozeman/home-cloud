locals {
  flake_path = "./${path.module}/nixos"
}

resource "random_string" "k3s_token" {
  length  = 32
  lower   = true
  numeric = true
  upper   = true
}

resource "local_file" "flake" {
  content = templatefile("${local.flake_path}/flake.tftpl", {
    hosts     = keys(var.k3s_nodes)
    k3s_token = random_string.k3s_token.result
  })

  filename        = "${local.flake_path}/flake.nix"
  file_permission = "600"
}

data "external" "instantiate" {
  for_each = var.k3s_nodes
  program  = ["${path.module}/instantiate.sh", "path:${local.flake_path}#nixosConfigurations.${each.key}"]

  depends_on = [
    local_file.flake
  ]
}

resource "null_resource" "deploy" {
  for_each = var.k3s_nodes

  triggers = {
    derivation = data.external.instantiate[each.key].result["path"]
    vm_id      = var.vm_ids[each.key]
  }

  provisioner "local-exec" {
    environment = {
      NIX_SSHOPTS = "-o StrictHostKeyChecking=no"
    }

    interpreter = concat(
      ["nix",
        "--extra-experimental-features", "nix-command flakes",
        "shell",
        "github:NixOS/nixpkgs/22.11#nixos-rebuild",
        "--command",
        "nixos-rebuild",
        "--fast",
        "--flake", "path:${local.flake_path}#${each.key}",
        "--target-host", "root@${each.key}",
        "--build-host", "root@${each.key}",
      ]
    )

    command = "switch"
  }

  depends_on = [
    # FIXME: cmopute the first node
    null_resource.deploy["k3s-01"]
  ]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = <<EOF
      set -e
      ssh -o StrictHostKeyChecking=no root@${keys(var.k3s_nodes)[0]} kubectl config view --raw | sed -e 's/127.0.0.1:6443/${var.k3s_name}:6443/' > ~/.kube/config
      chmod 600 ~/.kube/config
    EOF
  }

  triggers = {
    deploy = null_resource.deploy[keys(var.k3s_nodes)[0]].id

    file_empty = try(file("~/.kube/config"), "") == ""
  }

  depends_on = [
    null_resource.deploy
  ]
}
