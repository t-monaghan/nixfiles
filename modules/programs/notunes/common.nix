{lib, ...}: {
  options.nixfiles.programs.notunes.enable = lib.mkEnableOption "noTunes";
}
