{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs = { nixpkgs, home-manager, alacritty-theme, ... }:
    let
      inherit nixpkgs;
    in
    {
      homeConfigurations."tom.monaghan@tmonaghan-9WLJ0K" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ({ config, pkgs, ...}: {
            nixpkgs.overlays = [ alacritty-theme.overlays.default ];
          })
          ./home.nix
          ./hosts/culture-amp.nix
        ];
      };
      homeConfigurations."tmonaghan@thomass-mbp.lan" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./home.nix
          ./hosts/personal.nix
        ];
      };

      homeConfigurations."alanturing@Alans-Virtual-Machine.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./home.nix
          ./hosts/work-vm.nix
        ];
      };



    };
}
