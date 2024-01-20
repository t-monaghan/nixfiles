{ pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = with pkgs; {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.

    stateVersion = "23.11";
    packages = [
      nodePackages_latest.bash-language-server
      nodePackages_latest.typescript-language-server
      nodePackages_latest.vscode-langservers-extracted
      nil
      act
      asciinema
      nerdfonts
      udev-gothic-nf
      fastfetch
      python3
      python311Packages.python-lsp-server
      tree
      trash-cli
      yaml-language-server
      shellcheck
      # TODO: add rectangle once dots file is findable
    ];
  };
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    tmux.enable = true;
    gh.enable = true;

    thefuck.enable = true;
    thefuck.enableZshIntegration = true;

    mcfly = {
      enable = true;
      enableZshIntegration = true;
      keyScheme = "vim";
    };

    bat = {
      enable = true;
      config = {
        theme = "Monokai Extended";
      };
    };

    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "uew";
    };

    git = {
      enable = true;
      userName = "t-monaghan";
      userEmail = "tomaghan+git@gmail.com";
      aliases = {
        cob = "checkout -b";
        com = "checkout main";
        ck = "checkout";
      };
      extraConfig = {
        push.autoSetupRemote = true;
      };
    };

    helix = {
      enable = true;
      defaultEditor = true;
      themes = {
        tmonaghan = let
          transparent = "none"; 
        in {
          inherits = "autumn";
          "ui.background" = transparent;
          "ui.bufferline.active" = { fg = "#e69875";};
        };
      };
      settings = {
        theme = "tmonaghan"; # This should be tmonaghan for darwin, with transparent bg
        editor = {
          line-number = "relative";
          bufferline = "always";
          true-color = true;
        };      
        editor.statusline = {      
          left = ["spacer" "version-control" "position" "mode" "diagnostics"];
          right = ["workspace-diagnostics" "file-name" "spinner"];
        };
        keys.insert = {
          j.k = "normal_mode";
          C-l = ["goto_line_end" ":append-output echo -n ';'" "normal_mode"];
        };
        editor.file-picker = {
          hidden = false;
        };
      };
    };

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autocd = true;
      history = {
        ignoreAllDups = true;
      };
      envExtra = ". \"$HOME/.cargo/env\"";
      shellAliases = {
        chmox = "chmod a+x";
        f = "fuck";
        # Sometimes colourful language is best kept to ourselves
        woops = "fuck";
        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        ll = "ls -ltra";
        gd = "git diff";
        gdc = "git diff --cached";
        dvsp = "devbox run setup";
        dvsd = "devbox run seed";
        dvu = "devbox services up";
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          option_as_alt = "OnlyRight";
          decorations = "buttonless";
          opacity = 0.95;
          dimensions = {
            columns = 100;
            lines = 32;
            };
          dynamic_padding = true;
        };
        font.normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Regular";
        };
        font.size = 16.0;
        schemes = {
          everforest_dark_medium = "&everforest_dark_medium";
          primary = {
            background = "'#2d353b'";
            foreground = "'#d3c6aa'";
          };
          normal = {
            black   = "'#475258'";
            red     = "'#e67e80'";
            green   = "'#a7c080'";
            yellow  = "'#dbbc7f'";
            blue    = "'#7fbbb3'";
            magenta = "'#d699b6'";
            cyan    = "'#83c092'";
            white   = "'#d3c6aa'";
          };
          bright = {
            black  = "'#475258'";
            red    = "'#e67e80'";
            green  = "'#a7c080'";
            yellow = "'#dbbc7f'";
            blue   = "'#7fbbb3'";
            magenta= "'#d699b6'";
            cyan   = "'#83c092'";
            white  = "'#d3c6aa'";
          };
        # schemes = {
        #   # TODO: this isn't working, convert files to JSON
        #   colors = let importYaml = file: builtins.fromJSON (builtins.readFile (pkgs.runCommandNoCC "converted-yaml.json" ''${pkgs.yj}/bin/yj < "${file}" > "$out"'')); in importYaml ./themes/alacritty/everforest_dark_medium.yaml;
      };
    };
  };
  };
}
