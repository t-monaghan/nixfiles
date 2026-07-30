{
  pkgs,
  config,
  lib,
  colors,
  fonts,
  ...
}: let
  # Alacritty and jankyborders have no system-appearance hook, so they cannot
  # follow light/dark the way Ghostty, Neovim, bat and Zed do. Both take the
  # dark palette (see ./configs/colours.nix).
  palette = colors.palettes.dark;
in {
  imports = [
    ./shell.nix
    # One file per program; each sets its own `programs.<name>` /
    # `services.<name>` block, and takes `pkgs`, `lib`, `config`, `colors` and
    # `fonts` as module arguments (see ./args.nix).
    ./configs/aerospace.nix
    ./configs/claude-code.nix
    ./configs/ghostty.nix
    ./configs/neovim
    ./configs/opencode.nix
    ./configs/pi-coding-agent.nix
    ./configs/syncthing.nix
    ./configs/worktrunk.nix
    ./configs/zed.nix
  ];

  nix.package = pkgs.nix;
  nix.extraOptions = ''
    !include ${config.home.homeDirectory}/.config/secrets/access-tokens.conf
  '';

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
      # terminal-notifier: temporarily disabled. On this nixpkgs pin the package
      # isn't in any binary cache (cache.nixos.org 404s), so it builds from
      # source and cctools `ld` (1010.6) crashes while linking
      # `-framework ScriptingBridge -framework Cocoa` (Trace/BPT trap: 5, exit
      # 133) on aarch64-darwin. Upstream toolchain regression, not our config.
      # Re-enable once a nixpkgs bump ships a working linker, or pin it from a
      # known-good nixpkgs input.
      # terminal-notifier
      devbox
      nodejs
      sandy
      imds-broker

      # CLI tools
      pi-coding-agent
      uv

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
        active_color = "0xff${builtins.substring 1 6 palette.base0B}"; # green
        hidpi = "on";
        width = 8;
      };
    };
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

    ssh = {
      enable = true;
      # Opt out of the deprecated implicit `Host *` defaults; declare our own blocks.
      enableDefaultConfig = false;
      # Emitted as an `Include` at the top of ~/.ssh/config, ahead of our
      # match blocks. OrbStack manages this file for its VMs/containers.
      includes = ["~/.orbstack/ssh/config"];
      settings = {
        dolomite = {
          hostname = "ssh.dolomite.lan";
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

    # GUI Programs
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
            background = palette.base00;
            foreground = palette.base05;
          };
          normal = {
            black = palette.base00;
            red = palette.base08;
            green = palette.base0B;
            yellow = palette.base0A;
            blue = palette.base0D;
            magenta = palette.base0E;
            cyan = palette.base0C;
            white = palette.base06;
          };
          bright = {
            black = palette.base03;
            red = palette.base08;
            green = palette.base0B;
            yellow = palette.base0A;
            blue = palette.base0D;
            magenta = palette.base0E;
            cyan = palette.base0C;
            white = palette.base07;
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
