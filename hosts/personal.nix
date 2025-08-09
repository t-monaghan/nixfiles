{pkgs, ...}: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "tmonaghan";
    homeDirectory = "/Users/tmonaghan";
    packages = [
      devbox
    ];
  };

  # WARN: do not raise this to the shared homemanager config
  # as the work machine should not have direnv installed by nix
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global = {
      hide_env_diff = true;
      warn_timeout = "1h";
    };
  };
}
