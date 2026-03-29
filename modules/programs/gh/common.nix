{lib, ...}: {
  options.nixfiles.programs.gh.enable = lib.mkEnableOption "GitHub CLI";
}
