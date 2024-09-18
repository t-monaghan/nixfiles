{ pkgs, username, ... }: {

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

  programs.fish.functions = {
    clone = {
      description = "Clone a cultureamp repo";
      body = builtins.readFile ../dots/fish/scripts/clone.fish;
    };
  };

  programs.awscli = {
    enable = true;
  };
}
