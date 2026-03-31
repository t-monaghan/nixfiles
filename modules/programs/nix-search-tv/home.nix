{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.nix-search-tv.enable {
  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = false;
    settings.indexes = ["nixpkgs" "home-manager"];
  };
}
