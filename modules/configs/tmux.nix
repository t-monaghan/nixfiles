# Colours here name ANSI slots rather than hex values, so they follow the
# terminal's palette — which Ghostty sets per appearance mode from
# ./colours.nix. tmux doesn't participate in system light/dark switching itself,
# so this is what makes the pane border readable in both modes:
#
#   yellow / cyan / brightblack   base0A / base0C / base03
#   colour16                      base09, orange (no ANSI equivalent)
#   colour18                      base01, the lighter background
#   colour20                      base04, a mid-tone readable in BOTH modes
#                                 (this replaced a hand-picked hex value)
{
  pkgs,
  lib,
  ...
}: let
  # Preview is piped through `tail` so the bottom of the pane (where the action is)
  # stays visible when the preview window is shorter than the source pane.
  tmux-window-picker = pkgs.writeShellScript "tmux-window-picker" ''
    session="$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')"
    selected=$(${lib.getExe pkgs.tmux} list-windows -t "$session" -F '#{window_index}: #{pane_title}' \
      | ${lib.getExe pkgs.fzf} --no-sort --reverse --delimiter=':' \
        --preview "${lib.getExe pkgs.tmux} capture-pane -e -p -t '$session':{1} | tail -n \$FZF_PREVIEW_LINES" \
        --preview-window "right:80%")
    [ -n "$selected" ] && ${lib.getExe pkgs.tmux} select-window -t "$session:''${selected%%:*}"
  '';
  # Pick a repo from ~/dev, then pick either an existing worktree or an open
  # PR (most-recently-updated first), and open/attach a session that runs
  # `wt switch <branch>` / `wt switch pr:<n>` in it. Each fzf line carries two
  # hidden fields (kind, key) ahead of the displayed columns (--with-nth=3..).
  tmux-wt-switch = pkgs.writeShellScript "tmux-wt-switch" ''
    set -eu
    dev="$HOME/dev"

    repo=$(${pkgs.findutils}/bin/find "$dev" -maxdepth 1 -mindepth 1 -type d \
        -exec test -e '{}/.git' ';' -print \
      | sed "s|$dev/||" | sort \
      | ${lib.getExe pkgs.fzf} --reverse --prompt="repo> ") || exit 0
    [ -n "$repo" ] || exit 0
    repodir="$dev/$repo"

    # Stream worktrees and PRs into fzf from independent producers. This lets
    # fzf show local worktrees while the GitHub request is still in progress.
    line=$(
      {
        (
          wt list --format=json -C "$repodir" 2>/dev/null \
            | ${lib.getExe pkgs.jq} -r '
                def age: (now - .) as $s |
                  if   $s < 3600   then "\(($s/60)    | floor)m"
                  elif $s < 86400  then "\(($s/3600)  | floor)h"
                  elif $s < 604800 then "\(($s/86400) | floor)d"
                  else                  "\(($s/604800)| floor)w" end;
                .[]
                | select(.kind == "worktree" and (.is_main | not) and .branch)
                | "wt\t\(.branch)\t\u2442 \(.branch)\t\(.symbols // "")\t\(.commit.timestamp | age)\t\(.commit.message[0:60])"
              '
        ) &
        worktrees_pid=$!

        (
          cd "$repodir"
          ${lib.getExe pkgs.gh} pr list --state open --limit 50 \
            --json number,title,updatedAt,author,headRefName 2>/dev/null \
            | ${lib.getExe pkgs.jq} -r '
                sort_by(.updatedAt) | reverse | .[]
                | "pr\t\(.number)\t#\(.number)\t\(.updatedAt[0:10])\t@\(.author.login)\t\(.title)"
              '
        ) &
        prs_pid=$!

        wait "$worktrees_pid" || :
        wait "$prs_pid" || :
      } | ${lib.getExe pkgs.fzf} --reverse --delimiter='\t' --with-nth=3.. \
          --prompt="wt/pr ($repo)> "
    ) || exit 0
    [ -n "$line" ] || exit 0

    kind=$(printf '%s' "$line" | cut -f1)
    key=$(printf '%s' "$line" | cut -f2)
    [ -n "$key" ] || exit 0

    san=$(printf '%s' "$key" | tr '/.:' '-')
    case "$kind" in
      wt)
        # Prefer an already-running spawned-agent session for this branch.
        if ${lib.getExe pkgs.tmux} has-session -t "=pi-$san" 2>/dev/null; then
          ${lib.getExe pkgs.tmux} switch-client -t "pi-$san"; exit 0
        fi
        cmd="wt switch $key" ;;
      pr)
        cmd="wt switch pr:$key" ;;
      *) exit 0 ;;
    esac

    sess="$(printf '%s' "$repo" | tr './:' '-')-$san"
    if ! ${lib.getExe pkgs.tmux} has-session -t "=$sess" 2>/dev/null; then
      ${lib.getExe pkgs.tmux} new-session -d -s "$sess" -c "$repodir"
      ${lib.getExe pkgs.tmux} send-keys -t "$sess" "$cmd" Enter
    fi
    ${lib.getExe pkgs.tmux} switch-client -t "$sess"
  '';
  tmux-wt-create = pkgs.writeShellScript "tmux-wt-create" ''
    set -eu
    dev="$HOME/dev"

    repo=$(${pkgs.findutils}/bin/find "$dev" -maxdepth 1 -mindepth 1 -type d \
        -exec test -e '{}/.git' ';' -print \
      | sed "s|$dev/||" | sort \
      | ${lib.getExe pkgs.fzf} --reverse --prompt="repo> ") || exit 0
    [ -n "$repo" ] || exit 0
    cd "$dev/$repo"

    printf 'New branch (tfm/<name>): '
    IFS= read -r name || exit 0
    [ -n "$name" ] || exit 0

    branch="tfm/$name"
    if ! ${lib.getExe pkgs.git} check-ref-format --branch "$branch" >/dev/null 2>&1; then
      printf 'Invalid branch name: %s\nPress Enter to close.' "$branch"
      IFS= read -r _
      exit 1
    fi

    if ! ${lib.getExe pkgs.fish} -c 'wts -c $argv[1]' -- "$branch"; then
      printf '\nFailed to create worktree for %s.\nPress Enter to close.' "$branch"
      IFS= read -r _
      exit 1
    fi
  '';
  tmux-kill-session = pkgs.writeShellScript "tmux-kill-session" ''
    target=$1
    sesh last 2>/dev/null || ${lib.getExe pkgs.tmux} switch-client -n
    ${lib.getExe pkgs.tmux} kill-session -t "$target"
  '';
in {
  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 10;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    historyLimit = 50000;
    terminal = "screen-256color";
    extraConfig = ''
      set -g status off
      set -g detach-on-destroy off
      set -g pane-border-status top
      set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{?#{m:\[*,#{session_name}},#[fg=yellow]#{session_name}#[default],#{session_name}},#{pane_title}} #{?window_zoomed_flag, #[fg=cyan bold][ZOOMED]#[default],}#{?#{==:#{pane_index},0},#[align=right]#{S:#[default]─ #{?session_attached,#{?#{m:\[*,#{session_name}},#[fg=colour16],#[fg=brightblack]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#{?#{m:\[*,#{session_name}},#[fg=yellow],#[fg=colour20]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}#[default]──,}'
      bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
      bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

      # Splits and new windows should inherit the active pane's cwd, not the
      # session start directory (which for `wt switch` sessions is the primary
      # checkout, not the worktree the shell cd'd into).
      bind '"' split-window -v -c '#{pane_current_path}'
      bind % split-window -h -c '#{pane_current_path}'
      bind c new-window -c '#{pane_current_path}'

      # Vim-style visual selection in copy mode
      bind -Tcopy-mode-vi v send -X begin-selection
      bind -Tcopy-mode-vi y send -X copy-selection-and-cancel

      # Highlight the active pane while the prefix table is active. The format
      # avoids starting a shell and a sleeping process for each prefix press.
      set -g window-active-style 'bg=#{?client_prefix,colour18,default}'
      bind -Troot C-b switch-client -Tprefix

      # Open sesh picker instead of default session tree
      unbind s
      bind s display-popup -E -w 80% -h 80% "sesh picker -i"

      # Pick a repo, then a worktree or PR, and open/attach a `wt switch` session
      unbind w
      bind w display-popup -h 80% -w 80% -E "${tmux-wt-switch}"

      # Pick a repo, create a tfm/<name> branch and worktree, then open/attach
      # its tmux session through the `wts` fish function.
      bind -N "new tfm worktree" b display-popup -h 80% -w 80% -E "${tmux-wt-create}"

      # Switch windows via fzf picker (only if multiple windows)
      bind W if -F '#{?#{e|>:#{session_windows},1},1,}' 'display-popup -h 90% -w 90% -E "${tmux-window-picker}"' ""

      # Jump to the last window, or use the tmux last-session stack when there
      # is only one window. `l` is taken by pane navigation, so use Tab.
      bind -N "last-window-or-session" Tab if -F '#{e|>:#{session_windows},1}' 'last-window' 'switch-client -l'

      # Always use the same tmux last-session stack as the Tab fallback.
      bind -N "last-session" a switch-client -l

      # From a worktrunk worktree session (…/repo/.worktrees/branch), jump to the
      # session for the repository itself. `sesh connect --root <path>` resolves
      # the git worktree/repository root of that path and connects to its
      # session, creating it when it does not exist. `$(pwd)` is the pane's
      # directory: `run-shell` runs the command in the pane's working directory.
      # `m` is tmux's `select-pane -m` (mark pane) by default, which this
      # replaces.
      unbind m
      bind -N "root session (via sesh)" m run-shell "sesh connect --root $(pwd)"

      # Kill current session and switch to previous. Check the session count in
      # the tmux server and pass the target name to avoid two tmux client calls.
      bind X if -F '#{e|>:#{server_sessions},1}' 'run-shell "${tmux-kill-session} #{q:session_name}"' ""

      # Clone GitHub repo and open session
      bind g command-prompt -p "Clone GitHub repo ([org/]repo [dir]):" "run-shell -b 'tmux display-message \"Cloning %1...\" && fish -c \"ghclone %1\"'"

      # Notification bracket cleanup (`[work]` -> `work`) is intentionally NOT
      # tied to window/session switches — the bracket should persist as a
      # "needs attention" marker until you actually engage with pi.
      # `tmux-notify.ts` already unbrackets on `turn_start` (you sent input) and
      # `session_shutdown` (pi exited), which is the right trigger.
      # If a session ends up stuck bracketed (e.g. pi crashed), the next
      # `turn_start` from any pi in that session will clean it up; otherwise rename
      # by hand with `tmux rename-session work`.

      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
  };
}
