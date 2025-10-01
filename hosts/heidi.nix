{pkgs, ...}: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "thomas";
    homeDirectory = "/Users/thomas";
  };

}
