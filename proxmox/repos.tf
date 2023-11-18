
resource "null_resource" "repos_enterprise_disable" {
  for_each = var.pve_nodes

  triggers = {
    command = <<EOF
      set -e
      DEBIAN_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f2)
      ENTERPRISE_REPO_LIST="/etc/apt/sources.list.d/pve-enterprise.list"
      CEPH_REPO_LIST="/etc/apt/sources.list.d/ceph.list"
      FREE_REPO_FILE="/etc/apt/sources.list.d/pve.list"
      FREE_REPO_LIST="deb http://download.proxmox.com/debian/pve $DEBIAN_CODENAME pve-no-subscription"
      [ -f $ENTERPRISE_REPO_LIST ] && mv $ENTERPRISE_REPO_LIST $ENTERPRISE_REPO_LIST~
      [ -f $CEPH_REPO_LIST ] && mv $CEPH_REPO_LIST $CEPH_REPO_LIST~
      echo "$FREE_REPO_LIST" > $FREE_REPO_FILE
      EOF
  }

  provisioner "remote-exec" {
    inline = [self.triggers.command]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }
}

resource "null_resource" "repos_upgrade" {
  for_each = var.pve_nodes

  provisioner "remote-exec" {
    inline = [
      <<EOF
        set -e
        apt-get update -y
        apt-get upgrade -y
      EOF
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }
}
