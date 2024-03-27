{ pkgs, aerospace, ... }: {
  nixpkgs.config.allowUnfree = true;

  launchd.agents.aerospace.enable = true;
  launchd.agents.aerospace.config = {
    Label = "com.bobko.aerospace";
    Program = "/usr/bin/open";
    ProgramArguments = [ "-a" "Aerospace" "--started-at-login" ];
    RunAtLoad = true;
  };

  home = with pkgs; {
    stateVersion = "23.11";
    packages = import ./packages.nix { aerospace = aerospace; pkgs = pkgs; };
    file.alacritty-theme.source = ../dots/alacritty-colors.toml;
    file.alacritty-theme.target = ".config/alacritty/";
    file.aerospace.source = ../dots/aerospace.toml;
    file.aerospace.target = ".aerospace.toml";
  };
  programs = {
    home-manager.enable = true;

    helix = import ./helix.nix;

    alacritty = import ./alacritty.nix;

    gh.enable = true;
    gh-dash.enable = true;

    jq.enable = true;

    navi.enable = true;
    navi.enableFishIntegration = true;

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [ "--cmd j" ];
    };

    mcfly = {
      enable = true;
      enableFishIntegration = true;
      keyScheme = "vim";
      fzf.enable = true;
      interfaceView = "BOTTOM";
    };

    bat = {
      enable = true;
      config = {
        theme = "Monokai Extended";
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = builtins.fromTOML (builtins.readFile ../dots/starship.toml);
    };

    git = {
      enable = true;
      userName = "t-monaghan";
      userEmail = "tomaghan+git@gmail.com";
      extraConfig = {
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
        diff.tool = "difftastic";
        difftool.prompt = false;
        "difftool \"difftastic\"".cmd = ''difft "$LOCAL" "$REMOTE"'';
        pager.difftool = true;
      };
    };

    fish = {
      enable = true;

      loginShellInit = import ./fish-init.nix;

      shellAbbrs = {
        chmox = "chmod a+x";

        gco = "git checkout";
        gp = "git push";
        gpu = "git pull";
        gs = "git status";
        gl = "git log --compact-summary --oneline";
        gd = "git difftool";
        gdc = "git difftool --cached";
        ga = "git add";
        gc = "git commit -m";

        ll = "ls -ltra";

        dr = "devbox run";
        drs = "devbox run setup";
        drp = "devbox run populate";
        dsu = "devbox services up";

        rt = "trash-put";
      };

      functions = {
        starship_transient_rprompt_func = {
          body = ''starship module time'';
        };
      };

      plugins = [
        { inherit (pkgs.fishPlugins.foreign-env) name src; }
        {
          name = "pnpm-shell-completion";
          src = pkgs.fetchFromGitHub {
            owner = "g-plane";
            repo = "pnpm-shell-completion";
            rev = "v0.5.2";
            sha256 = "sha256-VCIT1HobLXWRe3yK2F3NPIuWkyCgckytLPi6yQEsSIE=";
          };
        }
      ];

    };

  };
}
