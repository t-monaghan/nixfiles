{ pkgs, ... }:
{
  imports = [
    ../home.nix
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
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh.initExtra = "fpath+=(/Users/tmonaghan/.nix-profile/share/zsh/site-functions)";
}
