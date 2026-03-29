{lib, ...}: {
  options.nixfiles.programs.alacritty.enable = lib.mkEnableOption "alacritty";
}
