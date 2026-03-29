{lib, ...}: {
  options.nixfiles.programs.aerospace.enable = lib.mkEnableOption "aerospace window manager";
}
