{lib, ...}: {
  options.nixfiles.programs.direnv.enable = lib.mkEnableOption "direnv";
}
