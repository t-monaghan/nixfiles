{lib, ...}: {
  options.nixfiles.programs.starship.enable = lib.mkEnableOption "starship prompt";
}
