{ lib, pkgs, username, ... }: {
  nixpkgs.config.allowUnfree = true;

  nix.gc.automatic = true;

  home = {
    stateVersion = "23.11";
    packages = import ./packages.nix { pkgs = pkgs; };
  };

  # TODO: aerospace plist
  launchd.agents.jankyborders = {
    enable = true;
    config = rec {
      Label = "com.felixkratz.jankyborders";
      Program = "/Users/${username}/.nix-profile/bin/borders";
      ProgramArguments = [ Program "width=8" "active_color=0xffcff1bf" "hidpi=on" ];
      RunAtLoad = true;
    };
  };

  xdg.configFile.aerospace = {
    source = ../dots/aerospace.toml;
    target = "aerospace/aerospace.toml";
  };

  programs = {

    home-manager.enable = true;

    helix = import ./helix.nix;

    alacritty = import ./alacritty.nix;

    fish = import ./fish.nix { pkgs = pkgs; };

    jq.enable = true;

    navi.enable = true;
    navi.enableFishIntegration = true;

    eza = {
      enable = true;
    };

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
    };

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
        theme = "gruvbox-light";
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
        diff.tool = "difftastic";
        difftool.prompt = false;
        "difftool \"difftastic\"".cmd = ''difft "$LOCAL" "$REMOTE"'';
        pager.difftool = true;
      };
      ignores = [ ".DS_Store" ];
    };

  };
}
