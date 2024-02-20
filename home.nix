{pkgs, ...}: let
  read-yaml = import ./helpers/read-yaml.nix {};
in {
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
      udev-gothic-nf
      python3
      python311Packages.python-lsp-server
      tree
      trash-cli
      yaml-language-server
      shellcheck
      gopls
      jdk11
      alejandra
      taplo
      killport
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
      fuzzySearchFactor = 4;
      fzf.enable = true;
    };

    fzf.enable = true;

    bat = {
      enable = true;
      config = {
        theme = "Monokai Extended";
      };
    };

    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ./dots/personal-posh.toml);
    };

    git = {
      enable = true;
      userName = "t-monaghan";
      userEmail = "tomaghan+git@gmail.com";
      aliases = {
        co = "checkout";
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
      # EXAMPLE: Of how to edit theme
      # themes = {
      #   tmonaghan = let
      #     transparent = "none";
      #   in {
      #     inherits = "base16_transparent";
      #     "ui.background" = transparent;
      #     "ui.bufferline.active" = {fg = "#e69875";};
      #   };
      # };
      languages = {
        language = [
          {
            name = "json";
            auto-format = false;
          }
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = "alejandra";
              args = ["--quiet"];
            };
          }
        ];
      };
      settings = {
        theme = "base16_transparent"; # This should be tmonaghan for darwin, with transparent bg
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
        gp = "git push";
        gl = "git log --compact-summary --oneline";
        ll = "ls -ltra";
        gd = "git diff";
        gdc = "git diff --cached";
        dr = "devbox run";
        drs = "devbox run setup";
        drp = "devbox run populate";
        dsu = "devbox services up";
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          option_as_alt = "Both";

          decorations = "buttonless";
          opacity = 0.95;
          dimensions = {
            columns = 100;
            lines = 32;
          };
          dynamic_padding = true;
        };
        font.normal = {
          family = "UDEV Gothic 35NF";
          style = "Regular";
        };
        font.size = 17.0;
        import = [pkgs.alacritty-theme.palenight];
      };
    };
  };
}
