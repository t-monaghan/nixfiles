{lib, ...}: {
  options.nixfiles.programs.betterdisplay.enable = lib.mkEnableOption "betterdisplay";
}
