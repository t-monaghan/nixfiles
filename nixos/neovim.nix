{
  pkgs,
  inputs,
  ...
}: let
  colors = import ./lib/colours.nix;
in {
  imports = [inputs.nixvim.nixosModules.nixvim];

  programs.nixvim = import ../modules/configs/neovim {
    inherit pkgs colors;
  };
}
