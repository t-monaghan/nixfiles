{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    wilma.url = "git+https://github.com/cultureamp/wilma?ref=feat/nix-flake-module";
    wilma.inputs.nixpkgs.follows = "nixpkgs";
    awtrix-cli.url = "git+https://github.com/t-monaghan/awtrix-cli";
    awtrix-cli.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    wilma,
    awtrix-cli,
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
