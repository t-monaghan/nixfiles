{ pkgs, ...}:
{
  home = with pkgs; {
    username = "tmonaghan";
    homeDirectory = "/Users/tmonaghan";
    packages = [
      unstable.devbox
    ];
  };
    programs.zsh.initExtra = "fpath+=(/Users/tmonaghan/.nix-profile/share/zsh/site-functions)";
}

