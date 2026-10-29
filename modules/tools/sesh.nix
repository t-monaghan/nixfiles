{
  config,
  lib,
  pkgs,
  ...
}: let
  hud-session = pkgs.writeShellApplication {
    name = "hud-session";
    runtimeInputs = [pkgs.tmux];
    text = builtins.readFile ./hud-session.sh;
  };
in {
  # Keep worktrunk worktrees (…/repo/.worktrees/branch) out of the zoxide
  # database so `sesh list` / the tmux session picker aren't cluttered with
  # long worktree paths. Active worktrees still show up in the picker via
  # their tmux session name (e.g. `pi-<branch>`), which is the short handle
  # we actually want. Colon-separated globs; `**` crosses `/`.
  home.sessionVariables._ZO_EXCLUDE_DIRS = lib.concatStringsSep ":" (
    ["${config.home.homeDirectory}/**/.worktrees/**"]
    ++ lib.optional config.nixfiles.context.role.work "${config.home.homeDirectory}/hotel"
  );

  programs.sesh = {
    enable = true;
    enableAlias = false;
    enableTmuxIntegration = false;
    settings = {
      # Also filter existing zoxide entries. _ZO_EXCLUDE_DIRS only prevents
      # zoxide from adding new worktree paths.
      blacklist = ["(^|/)\\.worktrees?(/|$)"];
      default_session.preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
      tui = {
        preview = true;
        show_icons = true;
        show_windows = true;
        preview_min_width = 80;
        preview_border = "line";
        window_name_format = "#{?#{pane_title},#{pane_title},#{window_name}}";
      };
      session = lib.mkIf config.nixfiles.context.role.desktop [
        {
          name = "dolomite";
          path = "~";
          startup_command = "ssh dolomite";
          preview_command = "echo 'SSH → dolomite (dolomite.lan)'";
          alias = "dol";
          alias_auto_connect = true;
        }
        {
          name = "notes";
          path = "~/notes";
          startup_command = "nvim ~/notes/notes.md && exit";
          preview_command = "bat ~/notes/notes.md";
          alias = "nd";
          alias_auto_connect = true;
        }
        {
          name = "nixfiles";
          path = "~/dev/nixfiles/";
          preview_command = "git status";
          alias = "nixf";
          alias_auto_connect = true;
        }
        {
          name = "hud";
          path = "~/dev";
          alias = "hud";
          alias_auto_connect = true;
          startup_command = "${lib.getExe hud-session} && exit";
        }
      ];
    };
  };
}
