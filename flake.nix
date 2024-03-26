{
  description = "Tom Monaghan's nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    aerospace.url = "github:t-monaghan/aerospace-flake";
    aerospace.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nix-darwin
    , nixpkgs
    , home-manager
    , aerospace
    ,
    }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [ pkgs.alacritty ];

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        # TODO: Make this use a variable
        nix.settings.trusted-users = [ "tom.monaghan" ];

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

        # homebrew = {
        #   enable = true;
        #   caskArgs.no_quarantine = true;
        #   global.brewfile = true;
        #   masApps = { };
        #   casks = [ "nikitabobko/tap/aerospace" "raycast" ];
        # };
      };
    in
    {
      # Build darwin flake using:
      darwinConfigurations.work = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            users.users."tom.monaghan".home = "/Users/tom.monaghan";
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users."tom.monaghan" = import ./hosts/culture-amp.nix;
              extraSpecialArgs = {
                inherit aerospace;
              };
            };
            nix. settings. ssl-cert-file = "/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem";
          }
        ];
      };
      darwinConfigurations. personal = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            users. users."tmonaghan". home = "/Users/tmonaghan";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."tmonaghan" = import ./hosts/personal.nix;
          }
        ];
      };
      # TODO: Figure out why this is needed
      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.personal.pkgs;
    };
}
