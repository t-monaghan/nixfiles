{lib, ...}: {
  options.nixfiles.programs.fish.enable = lib.mkEnableOption "fish shell";
}
