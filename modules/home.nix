{
  pkgs,
  config,
  lib,
  colors,
  ...
}: let
  ctx = config.nixfiles.context;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  palette = colors.palettes.dark;
in {
  imports = [
    ./shell.nix
    # One file per program under ./tools/
    # ./tools/aerospace.nix
    ./tools/alacritty.nix
    ./tools/claude-code.nix
    ./tools/ghostty.nix
    ./tools/hud.nix
    ./tools/neovim
    ./tools/omniwm.nix
    ./tools/opencode.nix
    ./tools/pi-coding-agent.nix
    ./tools/ssh.nix
    ./tools/syncthing.nix
    ./tools/worktrunk.nix
    ./tools/zed.nix
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  nix = lib.mkIf ctx.role.desktop {
    package = pkgs.nix;
    extraOptions = ''
      !include ${config.home.homeDirectory}/.config/secrets/access-tokens.conf
    '';
    gc.automatic = true;
  };

  home.packages = lib.mkIf ctx.role.desktop (with pkgs; [
    wakeonlan
    # GUI apps
    gum
    mos
    betterdisplay
    (callPackage ./tools/notunes-package.nix {})
    obsidian

    # Development tools
    devbox
    just
    pnpm
    nodejs
    sandy
    imds-broker
    jetbrains-mono
    nerd-fonts.jetbrains-mono

    # Linters
    golangci-lint
    golangci-lint-langserver
    shellcheck

    # Python LSP tools (formatters are provided via neovim extraPackages)
    python313
    python313Packages.python-lsp-ruff
    python313Packages.pyls-isort
    python313Packages.black
  ]);

  home.activation.mosDefaults = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
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
  '');

  services = lib.mkIf ctx.role.desktop {
    home-manager.autoExpire = {
      enable = true;
      store.cleanup = true;
    };

    jankyborders = {
      enable = false;
      settings = {
        active_color = "0xff${builtins.substring 1 6 palette.base0B}"; # green
        hidpi = "on";
        width = 8;
      };
    };
  };

  xdg.configFile = lib.mkIf ctx.role.desktop {
    "raycast-scripts" = {
      source = ./tools/raycast-scripts;
      recursive = true;
    };
    "sandy/config.json".text = builtins.toJSON {
      backend = "docker";
    };
  };

  programs.antigravity-cli.enable = lib.mkIf ctx.role.desktop true;
  programs.awtrix-cli = lib.mkIf isDarwin {
    enable = true;
    host = "192.168.1.97";
  };
}
