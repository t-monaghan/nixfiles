# NixOS system builder — the flake side of `nixos-rebuild switch --flake`.
#
# The whole flake `inputs` set is threaded to modules via specialArgs so a host
# module can pull NixOS modules straight from a locked input (e.g. nixvim — see
# ../nixos/neovim.nix), keeping them pinned by flake.lock instead of an ad-hoc
# fetchTarball.
#
# The target platform is declared per-host in its hardware-configuration.nix
# (`nixpkgs.hostPlatform`), so no `system` is passed here.
inputs @ {
  nixpkgs,
  home-manager,
  ...
}: {
  modules,
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs;};
  modules =
    [
      {nixpkgs.config.allowUnfree = true;}
      # Home-manager as a NixOS module: the box's user config (fish, starship,
      # tmux, …) reuses the same modules as the Macs (see ../nixos/home.nix →
      # ../modules/shell.nix). useGlobalPkgs shares the system nixpkgs (so
      # allowUnfree above applies); useUserPackages installs user packages into
      # the system profile.
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs;};
      }
    ]
    ++ modules;
}
