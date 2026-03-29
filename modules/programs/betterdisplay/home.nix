{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.programs.betterdisplay.enable {
  home.packages = [pkgs.betterdisplay];
}
