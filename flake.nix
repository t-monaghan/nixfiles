{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    mac-app-util,
  }: {
    homeConfigurations.work = let
      username = "thomas";
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          username = username;
          config.allowUnfree = true;
        };
        modules = [
          mac-app-util.homeManagerModules.default
          ./hosts/heidi.nix
        ];
        extraSpecialArgs = {
          inherit username;
        };
      };

    homeConfigurations.personal = let
      username = "tmonaghan";
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          username = username;
          config.allowUnfree = true;
        };
        modules = [
          mac-app-util.homeManagerModules.default
          ./hosts/personal.nix
        ];
        extraSpecialArgs = {
          inherit username;
        };
      };

    homeConfigurations.work-vm = let
      username = "alanturing";
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./hosts/work-vm.nix
        ];
        extraSpecialArgs = {
          inherit username;
        };
      };
  };
}
