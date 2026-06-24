{
  pkgs,
  lib,
  ...
}: {
  # Worktrunk (`wt`) — git worktree manager for parallel agent workflows.
  # https://worktrunk.dev
  #
  # The user config is managed declaratively via ./worktrunk-config.toml, which
  # is symlinked (read-only) to ~/.config/worktrunk/config.toml — edit that file
  # to change settings. Project config (.config/wt.toml) stays per-repo.

  home.packages = [pkgs.worktrunk];

  # Install fish shell integration after home-manager has linked its files.
  # `wt config shell install` writes a `wt` wrapper function + completions into
  # ~/.config/fish/{functions,completions}/wt.fish; these are regular files that
  # coexist with home-manager's symlinks. Idempotent and non-fatal.
  home.activation.worktrunkShellInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.worktrunk}/bin/wt config shell install fish --yes >/dev/null 2>&1 || true
  '';

  # See ./worktrunk-config.toml for the scaffold and inline documentation.
  xdg.configFile."worktrunk/config.toml".source = ./worktrunk-config.toml;
}
