{
  description = "Tom Monaghan's flake for system configuration across machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    {

      homeConfigurations.work =
        let
          username = "tom.monaghan";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            username = username;
            config.allowUnfree = true;
          };
          modules =
            [
              ./hosts/culture-amp.nix
            ];
          extraSpecialArgs = {
            inherit username;
          };
        };

      homeConfigurations.personal =
        let
          username = "tmonaghan";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            username = username;
            config.allowUnfree = true;
          };
          modules =
            [
              ./hosts/personal.nix
            ];
          extraSpecialArgs = {
            inherit username;
          };
        };

      homeConfigurations.work-vm =
        let
          username = "alanturing";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
          modules = [
            ./modules/home.nix
            ./hosts/work-vm.nix
          ];
          extraSpecialArgs = {
            inherit username;
          };
        };
    };
}
