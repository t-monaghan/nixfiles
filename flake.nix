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
      nix-darwin-configuration = import ./modules/nix-darwin.nix { pkgs = nixpkgs; self = self; };
    in
    {
      # Build darwin flake using:
      darwinConfigurations.work = nix-darwin.lib.darwinSystem {
        modules = [
          nix-darwin-configuration
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
            nix.settings.trusted-users = [ "tom.monaghan" ];
            nix.settings.ssl-cert-file = "/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem";
          }
        ];
      };
      darwinConfigurations.personal = nix-darwin.lib.darwinSystem {
        modules = [
          nix-darwin-configuration
          home-manager.darwinModules.home-manager
          {
            users.users."tmonaghan". home = "/Users/tmonaghan";
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users."tmonaghan" = import ./hosts/personal.nix;
              extraSpecialArgs = {
                inherit aerospace;
              };
            };
            nix.settings.trusted-users = [ "tmonaghan" ];
          }
        ];
      };
      # TODO: Figure out why this is needed
      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.personal.pkgs;
    };
}
