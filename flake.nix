{
  description = "Tom Monaghan's nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nix-darwin
    , nixpkgs
    , home-manager
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

        programs.zsh.enable = true;

        nixpkgs.config.allowUnfree = true;
        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        services.yabai.enable = true;
        services.yabai.config = {
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "on";
          window_placement = "second_child";
          window_opacity = "off";
        };
        services.yabai.extraConfig = ''
          yabai -m config layout bsp
          yabai -m rule --add app="^System Settings$" manage=off
        '';

        services.skhd.enable = true;
        services.skhd.skhdConfig = ''
          ctrl + alt - s : yabai -m window --swap recent

          ctrl + alt - r : yabai -m space --mirror y-axis

          ctrl + alt - h : yabai -m window --focus west
          ctrl + alt - j : yabai -m window --focus south
          ctrl + alt - k : yabai -m window --focus north
          ctrl + alt - l : yabai -m window --focus east

          # Not working
          ctrl + alt - n : yabai -m space --create
          ctrl + alt - d : yabai -m space --destroy

          ctrl + alt - left : yabai -m space --move prev
          ctrl + alt - right : yabai -m space --move next

          ctrl + alt + shift - left : yabai -m space --display 1
          ctrl + alt + shift - right : yabai -m space --display 2

        '';
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."tom.monaghan" = import ./hosts/culture-amp.nix;
          }
        ];
      };
      darwinConfigurations.personal = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            users.users."tmonaghan".home = "/Users/tmonaghan";
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
