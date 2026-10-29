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

  # Install fish shell integration after home-manager has linked its files, then
  # layer our own `wt` wrapper on top so NEW worktrees are named by their GitHub
  # PR number when one exists (see ./worktrunk-wt-wrapper.fish for the rationale).
  #
  # Steps (all write regular files into ~/.config/fish/{functions,completions},
  # which coexist with home-manager's symlinks; idempotent and non-fatal):
  #   1. `wt config shell install` writes worktrunk's own `wt` function +
  #      completions.
  #   2. Re-home worktrunk's `wt` function under `__wt_core` (via `wt config
  #      shell init`, renaming the definition) so our wrapper can delegate to it
  #      while keeping worktrunk's cd/exec directive handling intact.
  #   3. Overwrite the scaffolded `functions/wt.fish` with our PR-naming wrapper.
  home.activation.worktrunkShellInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    wtbin=${pkgs.worktrunk}/bin/wt
    fishfns="''${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions"
    mkdir -p "$fishfns"
    $wtbin config shell install fish --yes >/dev/null 2>&1 || true
    if $wtbin config shell init fish 2>/dev/null \
        | sed 's/^function wt$/function __wt_core/;s/^function wt /function __wt_core /' \
        > "$fishfns/__wt_core.fish.tmp"; then
      mv "$fishfns/__wt_core.fish.tmp" "$fishfns/__wt_core.fish"
    else
      rm -f "$fishfns/__wt_core.fish.tmp"
    fi
    install -m444 ${./worktrunk-wt-wrapper.fish} "$fishfns/wt.fish" || true
  '';

  # See ./worktrunk-config.toml for the scaffold and inline documentation.
  xdg.configFile."worktrunk/config.toml".source = ./worktrunk-config.toml;
}
