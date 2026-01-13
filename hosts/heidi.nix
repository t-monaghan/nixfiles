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
      kubernetes-helm
      kubernetes-helmPlugins.helm-git
      helmfile
      cursor-cli
      docker
      tfswitch
      nodejs_22
      postgresql
      (writeShellApplication
        {
          name = "terraform";
          runtimeInputs = [pkgs.tfswitch];
          text = ''
            ~/bin/terraform "$@"
          '';
        })
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
    ty.enable = true;
  };
}
