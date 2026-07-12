{
  pkgs,
  config,
  lib,
  flakePath,
  homeConfigName,
  ...
}: let
  fonts = import ./configs/fonts.nix;
  colors = import ./configs/colours.nix;
in {
  imports = [
    ./shell.nix
    ./configs/worktrunk.nix
    ./configs/pi-coding-agent.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  nix.gc.automatic = true;

  home = {
    stateVersion = "23.11";
    shell.enableFishIntegration = true;

    packages = with pkgs; [
      wakeonlan
      # GUI apps
      gum
      mos
      betterdisplay
      (callPackage ./configs/notunes-package.nix {})
      obsidian

      # Development tools
      nerd-fonts.jetbrains-mono
      jetbrains-mono
      pnpm
      just
      terminal-notifier
      devbox
      nodejs
      sandy
      imds-broker

      # CLI tools
      pi-coding-agent
      uv
      (pkgs.writeShellScriptBin "headroom" ''
        exec ${pkgs.uv}/bin/uvx --from 'headroom-ai[all]' headroom "$@"
      '')

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

    # Prewarm the uvx cache for headroom so the extension's 1.5s availability
    # probe (`headroom --help`) doesn't time out on first launch.
    activation.prewarmHeadroom = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.uv}/bin/uvx --from 'headroom-ai[all]' headroom --help >/dev/null 2>&1 || true
    '';

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

    syncthing = import ./configs/syncthing.nix {};
  };

  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = "1";
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

  xdg.configFile."sandy/config.json".text = builtins.toJSON {
    backend = "docker";
  };

  programs = {
    home-manager.enable = true;

    antigravity-cli.enable = true;

    nixvim = import ./configs/nixvim.nix {inherit pkgs colors flakePath homeConfigName;};

    ssh = {
      enable = true;
      # Opt out of the deprecated implicit `Host *` defaults; declare our own blocks.
      enableDefaultConfig = false;
      settings = {
        dolomite = {
          hostname = "dolomite.lan";
          user = "tom";
        };
      };
    };

    # sesh base config is shared (./shell.nix); the Mac adds an SSH session to
    # the dolomite box (which the box itself doesn't need).
    sesh.settings.session = [
      {
        name = "dolomite";
        path = "~";
        startup_command = "ssh dolomite";
        preview_command = "echo 'SSH → dolomite (dolomite.lan)'";
      }
    ];

    claude-code = import ./configs/claude-code.nix {};

    opencode = import ./configs/opencode.nix {inherit pkgs lib;};

    # GUI Programs
    aerospace = {
      enable = true;
      launchd.enable = true;
      settings = import ./configs/aerospace.nix {aerospace = config.programs.aerospace.package;};
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

    mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    };
  };
}
