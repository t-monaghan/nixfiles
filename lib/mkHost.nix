{
  home-manager,
  nixpkgs,
  nixpkgs-tv-pin,
  nixvim,
  awtrix-cli,
  sandy,
  imds-broker,
  ...
}: {
  name,
  username,
  system ? "aarch64-darwin",
  extraModules ? [],
}:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        sandy = sandy.packages.${final.system}.default;
        imds-broker = imds-broker.packages.${final.system}.default;
        television = (import nixpkgs-tv-pin {inherit system;}).television;
      })
    ];
  };
  modules =
    [
      nixvim.homeModules.nixvim
      awtrix-cli.homeManagerModules.default
      ../hosts/${name}.nix
    ]
    ++ extraModules;
  extraSpecialArgs = {inherit username;};
}
