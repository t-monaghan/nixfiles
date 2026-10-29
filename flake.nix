{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    awtrix-cli.url = "github:t-monaghan/awtrix-cli";
    awtrix-cli.inputs.nixpkgs.follows = "nixpkgs";
    imds-broker.url = "github:t-monaghan/imds-broker/feat/nix-flake";
    imds-broker.inputs.nixpkgs.follows = "nixpkgs";
    sandy.url = "github:t-monaghan/sandy/feat/nix-flake";
    sandy.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    mkHost = import ./lib/mkHost.nix inputs;
    mkNixosHost = import ./lib/mkNixosHost.nix inputs;
    darwinPkgs = nixpkgs.legacyPackages.aarch64-darwin;
    linuxPkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    formatter = {
      aarch64-darwin = darwinPkgs.alejandra;
      x86_64-linux = linuxPkgs.alejandra;
    };

    checks = {
      aarch64-darwin = {
        "tom.monaghan1" = self.homeConfigurations."tom.monaghan1".activationPackage;
        tmonaghan = self.homeConfigurations.tmonaghan.activationPackage;
      };
      x86_64-linux = {
        dolomite = self.nixosConfigurations.dolomite.config.system.build.toplevel;
      };
    };

    homeConfigurations = {
      "tom.monaghan1" = mkHost "tom.monaghan1";
      "tmonaghan" = mkHost "tmonaghan";
    };

    lib.mkDolomite = {extraModules ? []}:
      mkNixosHost {
        modules = [./hosts/dolomite/configuration.nix] ++ extraModules;
      };

    nixosConfigurations.dolomite = self.lib.mkDolomite {};
  };
}
