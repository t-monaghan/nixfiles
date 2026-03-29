{lib, ...}: {
  options.nixfiles.programs.zed.enable = lib.mkEnableOption "zed editor";
}
