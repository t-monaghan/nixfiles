# Home-manager user config for `dolomite` (user `tom`).
#
# Wired in via configuration.nix (`home-manager.users.tom = import ./home.nix`).
# The shell + CLI tooling is the shared module used by all three machines
# (../../modules/shell.nix); tool modules adapt via `nixfiles.context`.
{...}: {
  imports = [
    ../../modules/shell.nix
    ../../modules/tools/pi-coding-agent.nix
    ../../modules/tools/syncthing.nix
  ];

  home = {
    username = "tom";
    homeDirectory = "/home/tom";
    # Independent of the system's `system.stateVersion`; matches the Mac configs.
    stateVersion = "23.11";
  };

  nixfiles.context = {
    host = "dolomite";
    role = {
      desktop = false;
      homelab = true;
    };
  };

  programs.home-manager.enable = true;
}
