{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../modules/home.nix
  ];

  home = with pkgs; {
    username = username;
    homeDirectory = "/Users/${username}";
  };

  programs = {
    fish = {
      interactiveShellInit = "set -gx _ZO_EXCLUDE_DIRS $HOME/hotel";
      shellAbbrs = {
        "hsu" = "hotel services up";
        "hsl" = "hotel services logs --follow --all";
        "hsd" = "hotel services down";
        "hsls" = "hotel services list";
      };
      functions = {
        clone = {
          description = "Clone a cultureamp repo";
          body = builtins.readFile ../dots/fish/scripts/clone.fish;
        };
      };
    };

    awscli = {
      enable = true;
    };

    mise = {
      enable = true;
    };
  };
}
