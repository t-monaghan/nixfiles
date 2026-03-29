{lib, ...}: {
  options.nixfiles.programs.zoxide.enable = lib.mkEnableOption "zoxide";
}
