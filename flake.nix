{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
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
        modules = [./hosts/${name}.nix];
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
