{config, lib, ...}:
lib.mkIf config.nixfiles.programs.navi.enable {
  programs.navi = {
    enable = true;
    enableFishIntegration = true;
  };
}
