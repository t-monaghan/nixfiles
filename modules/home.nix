{
  pkgs,
  config,
  lib,
  awtrix-cli,
  my-flakes,
  ...
}: let
  fonts = import ./configs/fonts.nix;
  colors = import ./configs/colors.nix;
in {
  nixpkgs = {
    config.allowUnfree = true;
  };

  nix.gc.automatic = true;

  home = {
    stateVersion = "23.11";
    shell.enableFishIntegration = true;

    packages = with pkgs; [
      # GUI apps
      gum
      mos
      betterdisplay
      (callPackage ./configs/notunes-package.nix {})
      my-flakes.packages.${pkgs.system}.sandy
      my-flakes.packages.${pkgs.system}.imds-broker

      # Development tools
      wget
      nerd-fonts.jetbrains-mono
      jetbrains-mono
      eza
      pnpm
      just
      terminal-notifier
      devbox
      nodejs

      # CLI tools
      tree
      killport
      fblog
      hyperfine
      watchexec
      pi-coding-agent

      # Linters
      golangci-lint
      golangci-lint-langserver
      shellcheck

      # Formatters
      stylua
      nixpkgs-fmt
      alejandra
      ruff
      prettierd
      python313
      python313Packages.python-lsp-ruff
      python313Packages.pyls-isort
      python313Packages.black
    ];

    activation.mosDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
      /usr/bin/defaults write com.caldis.Mos showPreference 0
      /usr/bin/defaults write com.caldis.Mos SUEnableAutomaticChecks 0
      /usr/bin/defaults write com.caldis.Mos smoothMouse 1
      /usr/bin/defaults write com.caldis.Mos smooth 1
      /usr/bin/defaults write com.caldis.Mos reverse 1
      /usr/bin/defaults write com.caldis.Mos speed 2.50
      /usr/bin/defaults write com.caldis.Mos step 35.00
      /usr/bin/defaults write com.caldis.Mos stepX 10.00
      /usr/bin/defaults write com.caldis.Mos stepY 10.00
      /usr/bin/defaults write com.caldis.Mos duration 3.00
      /usr/bin/defaults write com.caldis.Mos durationTransition 0.30
    '';
  };

  services = {
    home-manager.autoExpire = {
      enable = true;
      store.cleanup = true;
    };

    jankyborders = {
      enable = true;
      settings = {
        active_color = "0xff${builtins.substring 1 6 colors.accent}";
        hidpi = "on";
        width = 8;
      };
    };
  };

  home.file.".pi/agent" = {
    source = ./configs/pi-coding-agent;
    recursive = true;
  };

  home.file.".pi/agent/AGENTS.md" = {
    text = ''
      ${builtins.readFile ./configs/agent-context/shared.md}

      ${builtins.readFile ./configs/agent-context/pi.md}
    '';
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";

  programs = {
    home-manager.enable = true;

    # Development
    go.enable = true;
    gemini-cli.enable = true;

    # CLI Tools
    ripgrep.enable = true;
    fd.enable = true;

    fish = import ./configs/fish.nix {inherit pkgs colors;};

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };

    difftastic = {
      enable = true;
      git = {
        diffToolMode = true;
        enable = true;
      };
    };

    git = {
      enable = true;
      signing.format = null;
      settings = {
        user.name = "t-monaghan";
        user.email = "tomaghan+git@gmail.com";
        push.autoSetupRemote = true;
        pull.rebase = true;
        init.defaultBranch = "main";
        pager.difftool = true;
        rerere.enabled = true;
      };
      ignores = [".DS_Store"];
    };

    bat = {
      enable = true;
      config = {
        theme-dark = colors.bat_dark;
        theme-light = colors.bat_light;
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = import ./configs/starship.nix {inherit colors;};
    };

    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    atuin = {
      enable = true;
      settings = {
        enter_accept = true;
        filter_mode_shell_up_key_binding = "session";
        workspaces = true;
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global = {
        hide_env_diff = true;
        warn_timeout = "1h";
      };
    };

    tmux = import ./configs/tmux.nix {inherit pkgs lib colors;};

    nixvim = import ./configs/nixvim.nix {inherit pkgs colors;};

    sesh = {
      enable = true;
      enableAlias = false;
      enableTmuxIntegration = false;
      settings = {
        default_session = {
          preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
        };
      };
    };

    television = {
      enable = true;
      enableFishIntegration = true;
      channels = import ./configs/television-channels.nix;
      settings = import ./configs/television-settings.nix;
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = false;
      settings.indexes = ["nixpkgs" "home-manager"];
    };

    claude-code = import ./configs/claude-code.nix {};

    opencode = import ./configs/opencode.nix {inherit pkgs lib;};

    navi = {
      enable = true;
      enableFishIntegration = true;
    };

    # GUI Programs
    aerospace = {
      enable = true;
      launchd.enable = true;
      settings = import ./configs/aerospace.nix;
    };

    ghostty = import ./configs/ghostty.nix {inherit colors;};

    alacritty = {
      enable = true;
      settings = {
        selection.save_to_clipboard = true;
        window = {
          opacity = 0.95;
          blur = true;
          decorations = "buttonless";
          dimensions = {
            columns = 100;
            lines = 50;
          };
        };
        font = {
          normal.family = fonts.mono;
          size = fonts.size;
        };
        colors = {
          primary = {
            background = colors.base00;
            foreground = colors.base05;
          };
          normal = {
            black = colors.base00;
            red = colors.base08;
            green = colors.base0B;
            yellow = colors.base0A;
            blue = colors.base0D;
            magenta = colors.base0E;
            cyan = colors.base0C;
            white = colors.base06;
          };
          bright = {
            black = colors.base03;
            red = colors.base08;
            green = colors.base0B;
            yellow = colors.base0A;
            blue = colors.base0D;
            magenta = colors.base0E;
            cyan = colors.base0C;
            white = colors.base07;
          };
        };
        mouse.hide_when_typing = true;
        scrolling.multiplier = 2;
      };
    };

    awtrix-cli = {
      enable = true;
      host = "192.18.1.97";
    };

    zed-editor = import ./configs/zed.nix {inherit pkgs lib colors;};
  };
}
