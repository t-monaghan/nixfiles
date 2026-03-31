{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.gh.enable {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
