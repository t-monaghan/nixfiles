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
