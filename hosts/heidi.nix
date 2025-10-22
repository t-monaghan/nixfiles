{pkgs, ...}: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "thomas";
    homeDirectory = "/Users/thomas";
    packages = [
      docker-credential-helpers
      pipx
    ];
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
