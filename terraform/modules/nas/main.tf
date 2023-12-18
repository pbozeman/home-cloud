locals {
  flake_path = "./${path.module}/nixos"
}

resource "local_file" "flake" {
  content = templatefile("${local.flake_path}/flake.tftpl", {
    nodes = var.nas_nodes
  })

  filename        = "${local.flake_path}/flake.nix"
  file_permission = "600"
}

data "external" "instantiate" {
  for_each = var.nas_nodes
  program  = ["${path.module}/instantiate.sh", "path:${local.flake_path}#nixosConfigurations.${each.key}"]

  depends_on = [
    local_file.flake
  ]
}

resource "null_resource" "datasets" {
  for_each = var.nas_nodes

  triggers = {
    # TODO: this could be scoped down more
    vars = sha1(jsonencode(var.nas_nodes))
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = each.value.ip
    }

    inline = [<<EOF
      set -e
      %{for name, value in each.value.shares}
      NAME="storage/${name}"
      echo Processing share ${name}...
      if ! zfs list -H -o name | grep -q "^$NAME"; then
        zfs create storage/${name}
      fi
      zfs set quota=${value.quota} $NAME
      zfs set compression=${value.compression} $NAME
      zfs set atime=${value.atime} $NAME
      zfs set com.sun:auto-snapshot=${value.auto-snapshot} $NAME
      zfs set sharenfs=${value.nfs} $NAME
      %{endfor}
    EOF
    ]
  }
}

resource "null_resource" "deploy" {
  for_each = var.nas_nodes

  triggers = {
    derivation = data.external.instantiate[each.key].result["path"]
    vm_id      = var.vm_ids[each.key]
  }

  provisioner "local-exec" {
    environment = {
    NIX_SSHOPTS = "-o StrictHostKeyChecking=no" }

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
    null_resource.datasets
  ]
}
