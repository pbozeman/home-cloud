{
  disks,
  zfs-disks,
  zfs-init-zpool,
  ...
}: let
  createDisk = name: device: {
    type = "disk";
    device = device;
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "storage";
          };
        };
      };
    };
  };

  createZpool = name: {
    type = "zpool";
    mode = "raidz";
    rootFsOptions = {
      compression = "on";
      "com.sun:auto-snapshot" = "false";
    };
    datasets = {};
  };

  # Create zfs paritions, only if requested
  disko-zfs-disks = if zfs-init-zpool then
    builtins.listToAttrs (map (disk: {
      name = disk.name;
      value = createDisk disk.name disk.device;
    }) zfs-disks)
  else {};

  # Create zpool, only if requested
  disko-zpool = if zfs-init-zpool then {
    storage = createZpool "storage";
  } else {};

in {
  disko.devices = {
    disk = disko-zfs-disks // {
      main = {
        type = "disk";
        device = builtins.elemAt disks 0;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "boot";
              start = "0";
              end = "1M";
              flags = [ "bios_grub" ];
            }
            {
              name = "ESP";
              start = "1M";
              end = "512M";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "root";
              start = "512M";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
          ];
        };
      };
    };
    zpool = disko-zpool;
  };
}
