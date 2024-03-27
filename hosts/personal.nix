{ pkgs, aerospace, ... }:
{
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "tmonaghan";
    homeDirectory = "/Users/tmonaghan";
    packages = [
      aerospace.packages.aarch64-darwin.default
      devbox
    ];
  };
  launchd.agents.aerospace = import ./aerospace-launchd-agent.nix;
  # TODO: could be good to config around the ENV print on reload
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
