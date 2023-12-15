resource "null_resource" "proxmox_iommu_config" {
  for_each = var.pve_iommu_nodes

  #
  # set the boot parameter
  #
  provisioner "file" {
    destination = "/etc/kernel/cmdline"
    content     = "root=ZFS=rpool/ROOT/pve-1 boot=zfs ${each.value.iommu_key}=on"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  #
  # add necessary kernel modules
  #
  provisioner "file" {
    destination = "/etc/modules"
    content     = <<EOF
# VFIO MODULES
vfio
vfio_iommu_type1
vfio_pci
# END VFIO MODULES
    EOF

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  #
  # black list modules
  #
  provisioner "file" {
    destination = "/etc/modprobe.d/iommu-blacklist.conf"
    content     = <<EOF
%{for module in each.value.blacklist~}
blacklist ${module}
%{endfor~}
    EOF

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  #
  # config vfio
  #
  provisioner "file" {
    destination = "/etc/modprobe.d/iommu-vfio.conf"
    content     = "options vfio-pci ids=${each.value.vfio_ids}"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }
  }

  #
  # refresh efi
  #
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = each.key
    }

    inline = [
      <<EOF
        set -e
        update-initramfs -u
        pve-efiboot-tool refresh
        reboot
      EOF
    ]
  }

  triggers = {
    vars = sha1(jsonencode(var.pve_iommu_nodes))
  }

  depends_on = [
    null_resource.proxmox_cluster_ready,
    null_resource.proxmox_repos_ready
  ]
}
