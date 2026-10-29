# Home-manager user config for `dolomite` (user `tom`).
#
# Wired in via configuration.nix (`home-manager.users.tom = import ./home.nix`).
# All three hosts import `modules/home.nix`; tool modules adapt via
# `nixfiles.context`.
{...}: {
  imports = [../../modules/home.nix];

  home = {
    username = "tom";
    homeDirectory = "/home/tom";
  };

  nixfiles.context = {
    host = "dolomite";
    role = {
      desktop = false;
      homelab = true;
    };
  };
}
