{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    wilma.url = "git+https://github.com/cultureamp/wilma?ref=feat/nix-flake-module";
    wilma.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    wilma,
  }: let
    mkHost = {
      name,
      username,
      system ? "aarch64-darwin",
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [
          nixvim.homeModules.nixvim
          wilma.homeModules.wilma
          ./hosts/${name}.nix
        ];
        extraSpecialArgs = {inherit username;};
      };
  in {
    homeConfigurations = {
      work = mkHost {
        name = "culture-amp";
        username = "tom.monaghan1";
      };
      personal = mkHost {
        name = "personal";
        username = "tmonaghan";
      };
    };
  };
}
