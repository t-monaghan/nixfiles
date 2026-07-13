{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    # TEMPORARY ROLLBACK — ld64 "libcxxhardeningfast" regression on aarch64-darwin.
    #
    # The nixos-unstable ld64 refactor (nixpkgs 23c052050234, PR #535508
    # "ld64: drop x86_64-darwin support") dropped
    # `hardeningDisable = [ "libcxxhardeningfast" ]` from ld64 and bumped it
    # 956.6 -> 957.1. The resulting `ld` is built with libc++ fast-hardening,
    # whose assertions abort via __builtin_trap() (`ld: Trace/BPT trap: 5`,
    # linker exit 133) when linking anything that pulls in notify-rust /
    # mac_notification_sys with `-dead_strip` + Apple frameworks — e.g.
    # starship and watchexec. Those aren't cached for aarch64-darwin, so they
    # build locally and fail, breaking `home-manager switch`.
    #
    # The upstream fix is nixpkgs PR #536365 ("ld64: disable hardening again"),
    # still OPEN on the `staging` branch. b5aa0fbd is the last nixos-unstable
    # rev with the working ld64 (956.6 + hardeningDisable). Restore
    # `nixos-unstable` once #536365 has landed and reached the channel.
    nixpkgs.url = "github:NixOS/nixpkgs/b5aa0fbd538984f6e3d201be0005b4463d8b09f8";
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
