# System-wide Neovim via nixvim.
#
# Imported by configuration.nix. Uses the flake's pinned `nixvim` input (see
# flake.nix / flake.lock) via specialArgs, so it stays in lockstep with the mac
# home configs and is bumped with `nix flake update` rather than a manual
# fetchTarball hash. The ported config lives under ./modules/neovim/.
#
# Sibling files it expects:
#   ./lib/colours.nix
#   ./modules/neovim/nixvim.nix
#   ./modules/neovim/neovim-plugins.nix
#   ./modules/neovim/neovim-lsp.nix
#   ./modules/neovim/neovim-obsidian.nix
{
  pkgs,
  inputs,
  ...
}: let
  colors = import ./lib/colours.nix;
in {
  imports = [inputs.nixvim.nixosModules.nixvim];

  programs.nixvim = import ./modules/neovim/nixvim.nix {
    inherit pkgs colors;
  };
}
