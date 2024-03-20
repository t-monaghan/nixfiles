{ pkgs, ... }: {
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
      yaml-language-server
      shellcheck
      gopls
      jdk11
      taplo
      killport
      trash-cli
      fzf
      _1password
      nixpkgs-fmt
      yabai
      skhd
      # TODO: add rectangle once dots file is findable
    ];
    file.yabai.target = ".config/yabai/yabairc";
    file.yabai.source = ./dots/yabairc;
    file.skhd.target = ".config/skhd/skhdrc";
    file.skhd.source = ./dots/skhdrc;
  };
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
    };

    gh.enable = true;
    jq.enable = true;

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
      settings = builtins.fromTOML (builtins.readFile ./dots/starship.toml);
    };

    git = {
      enable = true;
      userName = "t-monaghan";
      userEmail = "tomaghan+git@gmail.com";
      extraConfig = {
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
    };

    helix = {
      enable = true;
      defaultEditor = true;
      themes = {
        tmonaghan = {
          inherits = "sonokai";
          "ui.background" = { fg = "white"; };
          "ui.linenr.selected" = "#9ed072";
          "ui.bufferline" = { bg = "none"; };
          "ui.cursor" = {
            bg = "#9ed072";
            modifiers = [ "dim" ];
          };
          "ui.bufferline.active" = { modifiers = [ "reversed" ]; };
          "ui.selection.primary" = { modifiers = [ "reversed" ]; };
          "ui.statusline" = { bg = "none"; };
          "ui.popup" = { bg = "none"; };
          "ui.window" = { bg = "none"; };
          "ui.menu" = { bg = "none"; };
          "ui.help" = { bg = "none"; };
        };
      };
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
              command = "nixpkgs-fmt";
            };
          }
        ];
      };
      settings = {
        theme = "tmonaghan";
        editor = {
          line-number = "relative";
          bufferline = "always";
          true-color = true;
        };
        editor.statusline = {
          left = [ "spacer" "version-control" "position" "mode" "diagnostics" ];
          right = [ "workspace-diagnostics" "file-name" "total-line-numbers" "spinner" ];
        };
        keys.insert = {
          j.k = "normal_mode";
          C-l = [ "goto_line_end" ":append-output echo -n ';'" "normal_mode" ];
        };
        keys.normal = {
          space.F = "file_picker";
          space.f = "file_picker_in_current_directory";
        };
        editor.file-picker = {
          hidden = false;
        };
      };
    };

    fish = {
      enable = true;
      shellAbbrs = {
        chmox = "chmod a+x";

        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gco = "git checkout";
        gp = "git push";
        gpu = "git pull";
        gl = "git log --compact-summary --oneline";
        ll = "ls -ltra";
        gd = "git diff";
        gdc = "git diff --cached";

        dr = "devbox run";
        drs = "devbox run setup";
        drp = "devbox run populate";
        dsu = "devbox services up";

        rt = "trash-put";
        clone = "git clone git@github.com:cultureamp/";
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

      loginShellInit = ''
        bind \cx\ce edit_command_buffer

        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        end
        
        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fenv source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        end'';
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          option_as_alt = "Both";

          decorations = "buttonless";
          opacity = 0.70;
          blur = true;
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
        import = [ pkgs.alacritty-theme.gruvbox_dark ];
      };
    };
  };
}
