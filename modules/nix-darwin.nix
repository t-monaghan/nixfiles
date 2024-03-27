{ pkgs, self }: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.nixPath = [
    {
      darwin-config = "$HOME/.nixpkgs/darwin-configuration.nix";
      nixpkgs = pkgs;
    }
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # TODO: Investigate why this **MUST** be zsh. Breaks config if changed to fish/bash
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.defaults.dock.autohide = true;
}
