{ pkgs, self }: {
  services.nix-daemon.enable = true;

  nix.nixPath = [{ nixpkgs = pkgs; }];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # environment.shells = [ /etc/profiles/per-user/tom.monaghan/bin/fish ];

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;
    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;
    # Darwin config
    # https://daiderd.com/nix-darwin/manual/index.html
    defaults = {
      dock = {
        autohide = true;
        # can be one of {null, "genie", "suck", "scale"}
        mineffect = "scale";
        minimize-to-application = true;
        show-recents = false;
        # makes hidden apps translucent
        showhidden = true;
      };
      finder = {
        AppleShowAllFiles = true;
        ShowPathbar = true;
      };
      spaces.spans-displays = false;
      trackpad = {
        Clicking = true;
        Dragging = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
      NSGlobalDomain.NSWindowShouldDragOnGesture = true;
      NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
      NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
      # Whether to enable natural scroll direction
      NSGlobalDomain."com.apple.swipescrolldirection" = true;
    };
  };

  # TODO: Investigate why this **MUST** be zsh. Breaks config if changed to fish/bash
  programs = {
    zsh.enable = true;
    fish.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";


}
