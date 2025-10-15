{pkgs, ...}: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "thomas";
    homeDirectory = "/Users/thomas";
  };
  programs = {
    granted = {
      enableFishIntegration = true;
      enable = true;
    };
    pyenv = {
      enable = true;
    };
  };
}
