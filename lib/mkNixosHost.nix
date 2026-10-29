# NixOS system builder — the flake side of `nixos-rebuild switch --flake`.
#
# The whole flake `inputs` set is threaded to modules via specialArgs so a host
# module can pull NixOS modules straight from a locked input, keeping them pinned
# by flake.lock instead of an ad-hoc fetchTarball.
#
# The target platform is declared per-host in its hardware-configuration.nix
# (`nixpkgs.hostPlatform`), so no `system` is passed here.
inputs @ {
  self,
  nixpkgs,
  home-manager,
  nixvim,
  awtrix-cli,
  ...
}: {modules}:
nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs;};
  modules =
    [
      {
        nixpkgs = {
          config.allowUnfree = true;
          overlays = import ./overlays.nix inputs;
        };
      }
      # Home-manager as a NixOS module: the box's user config (fish, starship,
      # tmux, …) reuses the same modules as the Macs (see ../hosts/dolomite/home.nix
      # → ../modules/home.nix). useGlobalPkgs shares the system nixpkgs (so
      # allowUnfree and overlays above apply); useUserPackages installs user
      # packages into the system profile.
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.sharedModules = [
          nixvim.homeModules.nixvim
          awtrix-cli.homeManagerModules.default
          {nixfiles.context.flakePath = self.outPath;}
        ];
        # First activation takes over pre-existing dotfiles (e.g. an old
        # ~/.config/fish/config.fish or gh/config.yml). Move them aside instead
        # of aborting; HM owns them on subsequent switches.
        home-manager.backupFileExtension = "hm-bak";
      }
    ]
    ++ modules;
}
