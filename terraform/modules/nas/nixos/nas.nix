{ config,
  lib,
  pkgs,
  modulesPath,
  hostname,
  hostId,
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
  systemd.services.kopiaRepo = {
    description = "Create Kopia Repo";
    serviceConfig.Type = "oneshot";

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "multi-user.target" ];

    script = with pkgs; ''
      # HOME is needed to create the cache
      export HOME="/root"
      export KOPIA_CHECK_FOR_UPDATES=false

      # TODO: parse responses to make this a bit smarter about when
      # and how to do error recovery (keeping in mind that we are in
      # a set -e enviornment from systemd)
      ${kopia}/bin/kopia repository connect b2 \
          --bucket="${kopiaAuth.b2_bucket}" \
          --key-id="${kopiaAuth.b2_key_id}" \
          --key="${kopiaAuth.b2_application_key}" \
          --password="${kopiaAuth.repo_password}" || \
              ${kopia}/bin/kopia repository create b2 \
                 --bucket="${kopiaAuth.b2_bucket}" \
                 --key-id="${kopiaAuth.b2_key_id}" \
                 --key="${kopiaAuth.b2_application_key}" \
                 --password="${kopiaAuth.repo_password}"
    '';
  };
}
