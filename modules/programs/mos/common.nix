{lib, ...}: {
  options.nixfiles.programs.mos.enable = lib.mkEnableOption "mos";
}
