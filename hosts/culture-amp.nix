{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../modules/home.nix
  ];

  home = with pkgs; {
    username = username;
    homeDirectory = "/Users/${username}";
    packages = [
      rubyPackages_3_2.solargraph
    ];
  };

  xdg.configFile.direnv = {
    target = "direnv/direnv.toml";
    text = ''
      [global]
      hide_env_diff = true
      warn_timeout = "1h"
    '';
  };

  programs.fish.shellAbbrs = {
    "hsu" = "hotel services up";
    "hsl" = "hotel services logs --follow --all";
    "hsd" = "hotel services down";
    "hsls" = "hotel services list";
  };

  programs.fish.functions = {
    clone = {
      description = "Clone a cultureamp repo";
      body = builtins.readFile ../dots/fish/scripts/clone.fish;
    };
    git-https = {
      description = "Changes the git remote to https from ssh";
      body = builtins.readFile ../dots/fish/scripts/ssh-to-https.fish;
    };
  };

  programs.awscli = {
    enable = true;
  };
}
