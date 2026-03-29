{lib, ...}: {
  options.nixfiles.programs.fzf.enable = lib.mkEnableOption "fzf";
}
