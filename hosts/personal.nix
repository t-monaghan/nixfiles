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
    programs.gh-dash.settings = import ../dots/gh-dash.nix;
  };


  # TODO: could be good to config around the ENV print on reload
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
