{
  pkgs,
  config,
  lib,
  colors,
  ...
}: let
  palette = colors.palettes.dark;
in {
  imports = [
    ./shell.nix
    # One file per program under ./tools/
    # ./tools/aerospace.nix
    ./tools/alacritty.nix
    ./tools/claude-code.nix
    ./tools/ghostty.nix
    ./tools/neovim
    ./tools/opencode.nix
    ./tools/omniwm.nix
    ./tools/pi-coding-agent.nix
    ./tools/ssh.nix
    ./tools/syncthing.nix
    ./tools/worktrunk.nix
    ./tools/zed.nix
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

    packages = with pkgs; [
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
      uv
      sandy
      imds-broker
      jetbrains-mono
      nerd-fonts.jetbrains-mono

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

  xdg.configFile."hud/hud.toml".source = (pkgs.formats.toml {}).generate "hud.toml" (import ./tools/hud.nix {inherit config lib;});

  services = {
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

  xdg.configFile."raycast-scripts" = {
    source = ./tools/raycast-scripts;
    recursive = true;
  };

  xdg.configFile."sandy/config.json".text = builtins.toJSON {
    backend = "docker";
  };

  programs = {
    home-manager.enable = true;
    antigravity-cli.enable = true;
    awtrix-cli = {
      enable = true;
      host = "192.18.1.97";
    };
  };
}
