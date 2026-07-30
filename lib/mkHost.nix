{
  self,
  home-manager,
  nixpkgs,
  nixvim,
  awtrix-cli,
  sandy,
  imds-broker,
  ...
}: {
  name,
  username,
  # Attr name of this config under the flake's `homeConfigurations`
  # (e.g. "personal" / "work"). Threaded down to nixd so option-aware
  # completion targets this specific host's option schema.
  homeConfigName,
  system ? "aarch64-darwin",
  extraModules ? [],
}:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        sandy = sandy.packages.${final.stdenv.hostPlatform.system}.default;
        imds-broker = imds-broker.packages.${final.stdenv.hostPlatform.system}.default;
        # worktrunk 0.68.0 ships shell-detection tests that read the host
        # process table (`test_process_name_and_ppid_self`,
        # `test_probe_reports_invoked_name_for_sh`). The Nix build sandbox on
        # darwin hides other processes, so they panic and fail the build.
        # Skip just those two so the package still builds; the rest of the
        # suite (1371 tests) keeps running.
        worktrunk = prev.worktrunk.overrideAttrs (old: {
          checkFlags =
            (old.checkFlags or [])
            ++ [
              "--skip=shell::utils::tests::test_process_name_and_ppid_self"
              "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
            ];
        });
      })
    ];
  };
  modules =
    [
      nixvim.homeModules.nixvim
      awtrix-cli.homeManagerModules.default
      ../hosts/${name}.nix
    ]
    ++ extraModules;
  # `self.outPath` is this flake's source in the store: a stable, immutable,
  # host-independent path that `builtins.getFlake` can resolve regardless of
  # username or where the repo is checked out. Used by nixd (see
  # ../modules/configs/neovim/lsp.nix) for nixpkgs + option completion.
  extraSpecialArgs = {
    inherit username homeConfigName;
    flakePath = self.outPath;
  };
}
