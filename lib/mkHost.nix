{
  self,
  home-manager,
  nixpkgs,
  nixvim,
  awtrix-cli,
  ...
} @ inputs: username:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = import ./overlays.nix inputs;
  };
  modules = [
    nixvim.homeModules.nixvim
    awtrix-cli.homeManagerModules.default
    # `self.outPath` is this flake's source in the store: a stable, immutable,
    # host-independent path that `builtins.getFlake` can resolve regardless of
    # username or where the repo is checked out. Used by nixd (see
    # ../modules/tools/neovim/lsp.nix) for nixpkgs + option completion.
    {nixfiles.context.flakePath = self.outPath;}
    ../hosts/${username}.nix
  ];
  extraSpecialArgs = {
    inherit username;
  };
}
