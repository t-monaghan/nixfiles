{...}: {
  programs = {
    television = {
      enable = true;
      enableFishIntegration = true;
      channels = import ./television-channels.nix;
      settings = import ./television-settings.nix;
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = false;
      settings.indexes = ["nixpkgs" "home-manager" "nixos"];
    };
  };
}
