{
  pkgs,
  config,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  nix.gc.automatic = true;

  home = {
    stateVersion = "23.11";
    packages = import ./packages.nix {pkgs = pkgs;};

    # symlinked configuration files for writeable config that is still tracked by this repository
    file = {
      "${config.home.homeDirectory}/.config/zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/nixfiles/dots/zed/settings.json";
      "${config.home.homeDirectory}/.config/nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/nixfiles/dots/kickstart.nvim";
      "${config.home.homeDirectory}/.claude/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/nixfiles/dots/claude/CLAUDE.md";
    };
  };

  xdg.configFile.ghostty = {
    source = ../dots/ghostty;
    target = "ghostty/config";
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";

  services = {
    home-manager.autoExpire.enable = true;
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

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    sesh = {
      enable = true;
      settings.blacklist = ["/dev"];
    };

    aerospace = {
      enable = true;
      userSettings = ../dots/aerospace.nix;
    };

    alacritty = import ./alacritty.nix;

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      tmuxinator.enable = true;
      historyLimit = 50000;
      terminal = "screen-256color";
    };

    jq.enable = true;

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
        theme = "gruvbox-dark";
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
        pull.rebase = true;
        init.defaultBranch = "main";
        difftool.prompt = false;
        pager.difftool = true;
      };
      difftastic = {
        enable = false;
        enableAsDifftool = true;
      };
      ignores = [".DS_Store"];
    };
  };
}
