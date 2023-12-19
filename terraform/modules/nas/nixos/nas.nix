{ config,
  lib,
  pkgs,
  modulesPath,
  hostname,
  hostId,
  shares,
  kopiaAuth,
  ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  time.timeZone = "America/Los_Angeles";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  boot.extraModulePackages = [ ];
  boot.zfs.devNodes = "/dev/disk/by-partuuid";
  boot.zfs.extraPools = [ "storage" ];
  boot.zfs.forceImportRoot = false;

  fileSystems."/" = {
    device = "/dev/vda3";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/vda2";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = hostname;
  networking.hostId = hostId;
  networking.useNetworkd = true;

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.nfs.server = {
    enable = true;

    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  services.mullvad-vpn = {
    enable = true;
  };

  networking.firewall = {
    enable = true;
    # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };

  environment.systemPackages = with pkgs; [
    btop
    jq
    kopia
    mullvad
    mullvad-vpn
    zfs
  ];

  # oneshot job to create kopia repo
  systemd.services.kopia-repo-init = {
    description = "Kopia Repo Initialization";
    serviceConfig.Type = "oneshot";

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "multi-user.target" ];

    path = [ pkgs.kopia ];
    script = ''
      # HOME is needed to create the cache
      export HOME="/root"
      export KOPIA_CHECK_FOR_UPDATES=false

      # TODO: parse responses to make this a bit smarter about when
      # and how to do error recovery (keeping in mind that we are in
      # a set -e enviornment from systemd)
      kopia repository connect b2 \
          --bucket="${kopiaAuth.b2_bucket}" \
          --key-id="${kopiaAuth.b2_key_id}" \
          --key="${kopiaAuth.b2_application_key}" \
          --password="${kopiaAuth.repo_password}" || \
              kopia repository create b2 \
                 --bucket="${kopiaAuth.b2_bucket}" \
                 --key-id="${kopiaAuth.b2_key_id}" \
                 --key="${kopiaAuth.b2_application_key}" \
                 --password="${kopiaAuth.repo_password}"
    '';
  };

  # backup service
  #
  # TODO: run the backup off a zfs snapshot
  # Investigate what happens if a snapshot fails. We don't want the whole
  # script to fail.
  #
  # TODO: add monitoring
  systemd.services.kopia-backup = {
    description = "Kopia Backup Service";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kopia ];

    serviceConfig.ExecStart = let
      createBackupCommand = path: share:
        if share.backup then
          ''
            # HOME is needed to create the cache
            export HOME="/root"
            echo BACKUP ${path}
            kopia snapshot create /storage/${path}
          ''
        else
          ''
            echo SKIPPING ${path}
          '';

      backupCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList createBackupCommand shares);
    in
      pkgs.writeShellScript "backup-script" backupCommands;
  };

  # backup service timer
  # TODO: consider passing in the calendar entry. For homedirs, hourly is good.
  # For big media, we might want to do this at night.
  systemd.timers.kopia-backup-timer = {
    wantedBy = [ "timers.target" ];
    partOf = [ "kopia-backup.service" ];
    timerConfig = {
      OnCalendar = "hourly";
      Unit = "kopia-backup.service";
    };
  };
}
