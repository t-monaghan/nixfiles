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

  darwin.windowManager.aerospace = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../dots/aerospace.toml);
  };

  # TODO: could be good to config around the ENV print on reload
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
