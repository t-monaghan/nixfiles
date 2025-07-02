{ pkgs, username, ... }: {
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

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";

  programs = {

    neovim.enable = true;

    ripgrep.enable = true;

    fd.enable = true;

    home-manager.enable = true;

    helix = import ./helix.nix;

    alacritty = import ./alacritty.nix;

    fish = import ./fish.nix { pkgs = pkgs; };

    jq.enable = true;

    navi.enable = true;
    navi.enableFishIntegration = true;

    aerospace = {
      enable = true;
      userSettings = ../dots/aerospace.nix;
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
        diff.tool = "difftastic";
        difftool.prompt = false;
        "difftool \"difftastic\"".cmd = ''difft "$LOCAL" "$REMOTE"'';
        pager.difftool = true;
      };
      ignores = [ ".DS_Store" ];
    };

  };
}
