# unattended pvecm requires that all the proxmox pve nodes can ssh
# to each other
resource "null_resource" "proxmox_ssh_config" {
  for_each = var.pve_nodes

  provisioner "file" {
    content     = var.proxmox_ssh_privkey
    destination = "/root/.ssh/id_rsa"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  provisioner "file" {
    content     = var.proxmox_ssh_pubkey
    destination = "/root/.ssh/id_rsa.pub"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  provisioner "file" {
    content     = join("\n", concat([trimspace(var.proxmox_ssh_pubkey)], var.ssh_pubkeys))
    destination = "/root/.ssh/authorized_keys"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  provisioner "file" {
    content     = <<EOF
Host *
  StrictHostKeyChecking no
EOF
    destination = "/root/.ssh/config"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  triggers = {
    ssh_pubkeys = join("", var.ssh_pubkeys)
  }
}

# init cluster on using node 01
resource "null_resource" "proxmox_cluster" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.pve_nodes.pve-01.ip
    }
    inline = [
      "pvecm create pve-cluster"
    ]
  }

  depends_on = [
    null_resource.proxmox_ssh_config
  ]
}

# This will not remove nodes if they are removed from that map. 
# That will have to be done manually.
#
# FIXME: proxmox can get fairly grumpy and might end up in a borked state
# if there are parallel adds to a cluster of the 3rd node.  It seems it can't
# sort out which nodes should have quorum.  Move this to a stand along script
# that does these sequentially with pauses in between.
resource "null_resource" "proxmox_cluster_nodes" {
  for_each = var.pve_nodes

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.value.ip
    }
    inline = [
      "pvecm add ${var.pve_nodes.pve-01.ip} --use_ssh || pvecm status | grep ${each.key}"
    ]
  }

  depends_on = [
    null_resource.proxmox_cluster
  ]
}

resource "proxmox_virtual_environment_dns" "pve" {
  for_each = var.pve_nodes

  domain    = data.proxmox_virtual_environment_dns.pve[each.key].domain
  node_name = data.proxmox_virtual_environment_dns.pve[each.key].node_name

  servers = [
    "1.1.1.2",
    "1.0.0.2"
  ]

  depends_on = [
    null_resource.proxmox_cluster_nodes
  ]
}

data "proxmox_virtual_environment_dns" "pve" {
  for_each  = var.pve_nodes
  node_name = each.key

  depends_on = [
    null_resource.proxmox_cluster_nodes
  ]
}

