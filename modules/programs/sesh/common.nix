{lib, ...}: {
  options.nixfiles.programs.sesh.enable = lib.mkEnableOption "sesh";
}
