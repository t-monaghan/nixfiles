{lib, ...}: {
  options.nixfiles.programs.opencode.enable = lib.mkEnableOption "opencode";
}
