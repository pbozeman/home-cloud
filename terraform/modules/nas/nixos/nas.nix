{ config
, lib
, pkgs
, modulesPath
, hostname
, hostId
, users
, shares
, kopiaAuth
, tailscaleKey
, ...
}: {
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

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = hostname;
  networking.hostId = hostId;
  networking.useNetworkd = true;

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  services.cloud-init.settings.preserve_hostname = true;

  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users = lib.attrsets.mapAttrs
    (name: value: {
      isNormalUser = true;
      shell = "/run/current-system/sw/bin/nologin";
    })
    users;

  services.nfs.server = {
    enable = true;

    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    extraConfig = ''
      workgroup = WORKGROUP
      server role = standalone server
      dns proxy = no
      vfs objects = acl_xattr catia fruit streams_xattr;

      # Security
      client ipc max protocol = SMB3
      client ipc min protocol = SMB2_10
      client max protocol = SMB3
      client min protocol = SMB2_10
      server max protocol = SMB3
      server min protocol = SMB2_10
    '';

    shares =
      let
        # Filter shares to include only those with 'smb-name' set and not null.
        filteredShares = lib.filterAttrs
          (key: shareOpts:
            shareOpts ? "smb-name" && shareOpts."smb-name" != null
          )
          shares;

        # Convert the filtered shares into the desired Samba configuration.
        sambaShares = lib.mapAttrs'
          (key: shareOpts: lib.nameValuePair (shareOpts."smb-name") {
            path = "storage/${key}";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "create mask" = "0644";
            "directory mask" = "0755";
          })
          filteredShares;
      in
      sambaShares;
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

    serviceConfig.ExecStart =
      let
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

  #
  # Tailscale
  #
  # TODO: at the time this was added, this is an experiment in using
  # a tailscale router node for local access.  If keeping, move it to
  # its own vm.
  #
  # TODO: also add tailscale proxmox provider to approve node and subnet
  # routing
  #
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.extraUpFlags = "--advertise-routes=192.168.10.0/24";

  # create a oneshot job to authenticate to Tailscale
  #
  # TODO: I had been authing like this on my dev box for awhile, but
  # just noticed services.tailscale.authKeyFile. Look into how it functions
  # and if it is compatible with later setting 'expiry disabled'
  #
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      #
      # FIXME: move to OAuth (I experienced the hang)
      # see: https://github.com/tailscale/tailscale/issues/1728
      ${tailscale}/bin/tailscale up -authkey ${tailscaleKey} --advertise-routes=192.168.10.0/24
    '';
  };
}
