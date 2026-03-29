{lib, ...}: {
  options.nixfiles.development.enable = lib.mkEnableOption "development tools";
}
