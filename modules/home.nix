{ pkgs, username, ... }: {
  nixpkgs.config.allowUnfree = true;

  nix.gc.automatic = true;

  home = with pkgs; {
    stateVersion = "23.11";
    packages = import ./packages.nix { pkgs = pkgs; };
  };

  launchd.agents.jankyborders = {
    enable = true;
    config = {
      Label = "com.felixkratz.jankyborders";
      Program = "/etc/profiles/per-user/${username}/bin/borders";
      ProgramArguments = [ "width=8" "active_color=0xffcff1bf" ];
      RunAtLoad = true;
    };
  };
  darwin.windowManager.aerospace = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../dots/aerospace.toml);
  };

  programs = {

    home-manager.enable = true;

    helix = import ./helix.nix;

    alacritty = import ./alacritty.nix;

    fish = import ./fish.nix { pkgs = pkgs; };

    gh.enable = true;
    gh-dash.enable = true;

    jq.enable = true;

    navi.enable = true;
    navi.enableFishIntegration = true;

    tmux = {
      enable = true;
      mouse = true;
      escapeTime = 100;
      keyMode = "vi";
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
        theme = "Monokai Extended";
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
        init.defaultBranch = "main";
        diff.tool = "difftastic";
        difftool.prompt = false;
        "difftool \"difftastic\"".cmd = ''difft "$LOCAL" "$REMOTE"'';
        pager.difftool = true;
      };
    };

  };
}
