{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
        nixosConfigurations.nas-01 = let
      hostname = "nas-01";
      hostId = "00010001";
    in nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit hostname hostId;
      };
      modules = [
        ./nas.nix
      ];
    };
      };
}
