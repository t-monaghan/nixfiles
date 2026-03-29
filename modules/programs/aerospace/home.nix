{config, lib, ...}:
lib.mkIf config.nixfiles.programs.aerospace.enable {
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    settings = import ./settings.nix;
  };
}
