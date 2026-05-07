{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pin nixpkgs for television 0.15.4 - 0.15.6 broke execute mode with tmux
    # https://github.com/alexpasmantier/television/pull/998
    nixpkgs-tv-pin.url = "github:NixOS/nixpkgs/68d8aa3d661f0e6bd5862291b5bb263b2a6595c9";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    wilma.url = "git+https://github.com/cultureamp/wilma?ref=feat/nix-flake-module";
    wilma.inputs.nixpkgs.follows = "nixpkgs";
    awtrix-cli.url = "git+https://github.com/t-monaghan/awtrix-cli";
    awtrix-cli.inputs.nixpkgs.follows = "nixpkgs";
    imds-broker.url = "github:t-monaghan/imds-broker/feat/nix-flake";
    imds-broker.inputs.nixpkgs.follows = "nixpkgs";
    sandy.url = "github:t-monaghan/sandy/feat/nix-flake";
    sandy.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-tv-pin,
    home-manager,
    nixvim,
    wilma,
    awtrix-cli,
    imds-broker,
    sandy,
  }: let
    mkHost = {
      name,
      username,
      system ? "aarch64-darwin",
      extraModules ? [],
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              sandy = sandy.packages.${final.system}.default;
              imds-broker = imds-broker.packages.${final.system}.default;
              television = (import nixpkgs-tv-pin { inherit system; }).television;
            })
          ];
        };
        modules =
          [
            nixvim.homeModules.nixvim
            awtrix-cli.homeManagerModules.default
            ./hosts/${name}.nix
          ]
          ++ extraModules;
        extraSpecialArgs = {inherit username;};
      };
  in {
    homeConfigurations = {
      work = mkHost {
        name = "culture-amp";
        username = "tom.monaghan1";
        extraModules = [wilma.homeManagerModules.wilma];
      };
      personal = mkHost {
        name = "personal";
        username = "tmonaghan";
      };
    };
  };
}
