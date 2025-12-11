{pkgs, ...}: {
  imports = [
    ../modules/home.nix
    ../modules/work/brew.nix
  ];
  home = with pkgs; {
    username = "thomas";
    homeDirectory = "/Users/thomas";
    packages = [
      docker-credential-helpers
      docker-compose
      pipx
      mongodb-compass
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
    fish.shellInit = ''
      fish_add_path /opt/homebrew/sbin
      fish_add_path /opt/homebrew/bin
    '';
  };
}
