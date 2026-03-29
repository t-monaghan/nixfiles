{lib, ...}: {
  options.nixfiles.programs.git.enable = lib.mkEnableOption "git";
}
