# FIXME: use passed in vars

module "first" {
  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host = "root@k3s-01"

  flake = "./${path.module}/nixos#first"

  arguments = [
    # You can build on another machine, including the target machine, by
    # enabling this option, but if you build on the target machine then make
    # sure that the firewall and security group permit outbound connections.
    "--build-host", "root@k3s-01"
  ]

  ssh_options = "-o StrictHostKeyChecking=accept-new"
}

module "subsequent" {
  for_each = toset(["k3s-02", "k3s-03"])

  source = "github.com/Gabriella439/terraform-nixos-ng/nixos"

  host = "root@${each.value}"

  flake = "./${path.module}/nixos#subsequent"

  arguments = [
    # You can build on another machine, including the target machine, by
    # enabling this option, but if you build on the target machine then make
    # sure that the firewall and security group permit outbound connections.
    "--build-host", "root@${each.value}"
  ]

  ssh_options = "-o StrictHostKeyChecking=accept-new"

  # FIXME: make a depends on first
}
