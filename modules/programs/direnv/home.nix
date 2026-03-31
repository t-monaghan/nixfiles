{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.direnv.enable {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global = {
      hide_env_diff = true;
      warn_timeout = "1h";
    };
  };
}
