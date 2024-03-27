{
  description = "Tom Monaghan's flake for system configuration across machines";

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
      nix-darwin-configuration = import ./modules/nix-darwin.nix { pkgs = nixpkgs; self = self; };
    in
    {
      darwinConfigurations.work =
        let
          username = "tom.monaghan";
        in
        nix-darwin.lib.darwinSystem {
          modules = [
            nix-darwin-configuration
            home-manager.darwinModules.home-manager
            {
              users.users.${username}.home = "/Users/${username}";
              nix.settings.trusted-users = [ "${username}" ];
              nix.settings.ssl-cert-file = "/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./hosts/culture-amp.nix;
                extraSpecialArgs = {
                  inherit aerospace;
                };
              };
            }
          ];
        };
      darwinConfigurations.personal =
        let
          username = "tmonaghan";
        in
        nix-darwin.lib.darwinSystem {
          modules = [
            nix-darwin-configuration
            home-manager.darwinModules.home-manager
            {
              users.users.${username}.home = "/Users/${username}";
              nix.settings.trusted-users = [ "${username}" ];
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./hosts/personal.nix;
                extraSpecialArgs = {
                  inherit aerospace;
                };
              };
            }
          ];
        };
      # TODO: Figure out why this is needed
      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.personal.pkgs;

      homeConfigurations.work-vm = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./modules/home.nix
          ./hosts/work-vm.nix
        ];
      };
    };
}
