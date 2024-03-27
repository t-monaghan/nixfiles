{ pkgs, aerospace, ... }: {
  nixpkgs.config.allowUnfree = true;

  launchd.agents.aerospace = import ./aerospace-launchd-agent.nix;

  home = with pkgs; {
    stateVersion = "23.11";
    packages = import ./packages.nix { aerospace = aerospace; pkgs = pkgs; };
    file = import ./dots-importer.nix;
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
