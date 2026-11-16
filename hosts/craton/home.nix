# Home-manager user config for `craton` (user `tom`).
{...}: {
  imports = [
    ../../modules/context.nix
    ../../modules/theme
    ../../modules/tools/neovim
    ../../modules/tools/git.nix
  ];

  home = {
    stateVersion = "26.05";
    username = "tom";
    homeDirectory = "/home/tom";
  };

  nixfiles.context = {
    host = "craton";
    role = {
      desktop = false;
      homelab = true;
    };
  };
}
