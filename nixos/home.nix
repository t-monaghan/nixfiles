# Home-manager user config for `dolomite` (user `tom`).
#
# Wired in via configuration.nix (`home-manager.users.tom = import ./home.nix`).
# The shell + CLI tooling is the shared module used by all three machines
# (../modules/shell.nix); anything Mac-only inside it is guarded by
# `pkgs.stdenv.isDarwin`, so on this Linux box it evaluates to the generic
# baseline. Box-only additions (if any) go here.
{...}: {
  imports = [../modules/shell.nix];

  home = {
    username = "tom";
    homeDirectory = "/home/tom";
    # Independent of the system's `system.stateVersion`; matches the Mac configs.
    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
}
