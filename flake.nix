{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
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
    home-manager,
    nixvim,
    awtrix-cli,
    imds-broker,
    sandy,
  } @ inputs: let
    mkHost = import ./lib/mkHost.nix inputs;
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
