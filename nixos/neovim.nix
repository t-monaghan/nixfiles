{
  pkgs,
  inputs,
  ...
}: let
  # Shared with the Macs (see ../modules/configs/colours.nix).
  colors = import ../modules/configs/colours.nix;
in {
  imports = [inputs.nixvim.nixosModules.nixvim];

  programs.nixvim = import ../modules/configs/neovim {
    inherit pkgs colors;
  };
}
