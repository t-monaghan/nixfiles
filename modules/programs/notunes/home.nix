{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.programs.notunes.enable {
  home.packages = [
    (pkgs.callPackage ./package.nix {})
  ];
}
