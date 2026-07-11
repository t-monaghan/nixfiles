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
  # ./configs/neovim-lsp.nix) for nixpkgs + option completion.
  extraSpecialArgs = {
    inherit username homeConfigName;
    flakePath = self.outPath;
  };
}
