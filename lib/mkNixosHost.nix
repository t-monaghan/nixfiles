# NixOS system builder — the flake side of `nixos-rebuild switch --flake`.
#
# The whole flake `inputs` set is threaded to modules via specialArgs so a host
# module can pull NixOS modules straight from a locked input (e.g. nixvim — see
# ../nixos/neovim.nix), keeping them pinned by flake.lock instead of an ad-hoc
# fetchTarball.
#
# The target platform is declared per-host in its hardware-configuration.nix
# (`nixpkgs.hostPlatform`), so no `system` is passed here.
inputs @ {nixpkgs, ...}: {
  modules,
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs;};
  modules =
    [
      {nixpkgs.config.allowUnfree = true;}
    ]
    ++ modules;
}
