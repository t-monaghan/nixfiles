{lib, ...}: {
  options.nixfiles.programs.navi.enable = lib.mkEnableOption "navi";
}
