{config, lib, ...}:
lib.mkIf config.nixfiles.programs.television.enable {
  programs.television = {
    enable = true;
    enableFishIntegration = true;
    channels = import ./channels.nix;
    settings = import ./settings.nix;
  };
}
