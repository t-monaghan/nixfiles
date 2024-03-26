{ pkgs, ... }:
{
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
  # TODO: could be good to config around the ENV print on reload
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
}
