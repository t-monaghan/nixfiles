{lib, ...}: {
  options.nixfiles.programs.ghostty.enable = lib.mkEnableOption "ghostty";
}
