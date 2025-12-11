{
  pkgs,
  config,
  ...
}: {
  nixpkgs = {
    config.allowUnfree = true;
  };

  nix.gc.automatic = true;

  home = {
    stateVersion = "23.11";
    packages = import ./packages.nix {pkgs = pkgs;};

    shell.enableFishIntegration = true;

    # symlinked configuration files for writeable config that is still tracked by this repository
    file = {
      "${config.home.homeDirectory}/.config/zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/nixfiles/dots/zed/settings.json";
      "${config.home.homeDirectory}/.config/nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/nixfiles/dots/kickstart.nvim";
    };
  };

  xdg.configFile.ghostty = {
    source = ../dots/ghostty;
    target = "ghostty/config";
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";

  services = {
    home-manager.autoExpire = {
      enable = true;
      store.cleanup = true;
    };

    jankyborders = {
      enable = true;
      settings = {
        active_color = "0xffcff1bf";
        hidpi = "on";
        width = 8;
      };
    };
  };

  programs = {
    home-manager.enable = true;

    fish = import ./fish.nix {pkgs = pkgs;};

    go.enable = true;

    gemini-cli.enable = true;

    claude-code = {
      enable = true;
      # skillsDir = ../dots/claude/skills;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global = {
        hide_env_diff = true;
        warn_timeout = "1h";
      };
    };

    sesh = {
      enable = true;
      enableAlias = false; # saves 's' alias for sesh's television channel
      settings = {
        blacklist = ["/dev"];
        default_session = {
          preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
        };
      };
    };

    aerospace = {
      enable = true;
      userSettings = import ../dots/aerospace.nix;
    };

    alacritty = import ./alacritty.nix;

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      historyLimit = 50000;
      terminal = "screen-256color";
      extraConfig = ''
        bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
        bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down'';
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = false;
      settings.indexes = ["nixpkgs" "home-manager"];
    };

    television = {
      enable = true;
      enableFishIntegration = true;
      channels = import ../dots/television/channels.nix;
      settings = import ../dots/television/config.nix;
    };

    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };

    ripgrep.enable = true;

    fd.enable = true;

    navi = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = ["--cmd j"];
    };

    atuin = {
      enable = true;
      # there is an issue where atuin creates a config file in shell hook: https://github.com/nix-community/home-manager/issues/5734
      # workaround is to remove the default config file and run hm switch in sh
      settings = {
        # inline_height = 10;
        enter_accept = true;
        filter_mode_shell_up_key_binding = "session";
        workspaces = true;
      };
    };

    bat = {
      enable = true;
      config = {
        theme-dark = "gruvbox-dark";
        theme-light = "gruvbox-light";
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = import ../dots/starship.nix;
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
      settings = {
        user.name = "t-monaghan";
        user.email = "tomaghan+git@gmail.com";
        push.autoSetupRemote = true;
        pull.rebase = true;
        init.defaultBranch = "main";
        pager.difftool = true;
      };
      ignores = [".DS_Store"];
    };
  };
}
