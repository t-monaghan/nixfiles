{ pkgs, ... }: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "tom.monaghan";
    homeDirectory = "/Users/tom.monaghan";
    packages = [
      nodejs_18
      nodePackages.pnpm
      yarn
      rubyPackages_3_2.solargraph
      ollama
    ];
  };

  xdg.configFile.direnv-fish = {
    target = "fish/conf.d/direnv/fish";
    text = "set -gx DIRENV_WARN_TIMEOUT '1h'";
  };
  # TODO: the below option and DIRENV_WARN_TIMEOUT live together
  xdg.configFile.direnv = {
    target = "direnv/direnv.toml";
    text = ''
      [global]
      hide_env_diff = true
    '';
  };
  programs.fish.functions = {
    clone = {
      description = "Clone a cultureamp repo";
      body = ''if set -q argv[2]
                  git clone git@github.com:cultureamp/"$argv[1]" "$argv[2..-1]"
               else
                  git clone git@github.com:cultureamp/"$argv[1]"
                  cd "$argv[1]"
               end'';
    };
  };

  programs.awscli = {
    enable = true;
  };
}
