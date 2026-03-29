{config, lib, ...}:
lib.mkIf config.nixfiles.programs.starship.enable {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
    settings = import ./settings.nix;
  };
}
