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

      set -gx DYLD_LIBRARY_PATH "/opt/homebrew/lib:$DYLD_LIBRARY_PATH"

      if test -d (brew --prefix)"/share/fish/completions"
          set -gx fish_complete_path (brew --prefix)/share/fish/completions $fish_complete_path
      end

      if test -d (brew --prefix)"/share/fish/vendor_completions.d"
          set -gx fish_complete_path (brew --prefix)/share/fish/vendor_completions.d $fish_complete_path
      end
    '';
  };
}
