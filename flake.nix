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

    # Optional private overlay (see README). The default is the empty local
    # stub; `scripts/switch nixos` overrides it with the real private repo on
    # the box. The `?narHash=` pin is REQUIRED: without it, Nix (>=2.24) treats
    # a relative `path:` input as "unlocked" and aborts every lock-touching
    # operation (even `switch` on a dirty tree) with
    # "lock file contains unlocked input". The hash is content-based and stable
    # across checkouts; if you ever edit private-stub/, refresh it with
    # `nix hash path ./private-stub`.
    private.url = "path:./private-stub?narHash=sha256-j2bEuE1ydf4I+oU97SWuhdelGq4XW1pHjPN5dF9XzF4=";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    awtrix-cli,
    imds-broker,
    sandy,
    private,
  } @ inputs: let
    mkHost = import ./lib/mkHost.nix inputs;
    mkNixosHost = import ./lib/mkNixosHost.nix inputs;
  in {
    homeConfigurations = {
      work = mkHost {
        name = "culture-amp";
        username = "tom.monaghan1";
        homeConfigName = "work";
      };
      personal = mkHost {
        name = "personal";
        username = "tmonaghan";
        homeConfigName = "personal";
      };
    };

    nixosConfigurations = {
      dolomite = mkNixosHost {
        modules = [
          ./nixos/configuration.nix
          private.nixosModules.dolomite
        ];
      };
    };
  };
}
