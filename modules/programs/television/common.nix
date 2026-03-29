{lib, ...}: {
  options.nixfiles.programs.television.enable = lib.mkEnableOption "television";
}
