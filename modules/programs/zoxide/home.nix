{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.zoxide.enable {
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
