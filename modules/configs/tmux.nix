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
  # List each tmux session as a parent row followed by its window rows. Hidden
  # stable IDs drive selection and previews. The picker preserves tmux order and
  # supports filtering by session or window name.
  tmux-window-picker = pkgs.writeShellScript "tmux-window-picker" ''
    selected=$(
      {
        for session_id in $(${lib.getExe pkgs.tmux} list-sessions -F '#{session_id}'); do
          session_name=$(${lib.getExe pkgs.tmux} display-message -p -t "$session_id" '#{session_name}')
          session_pane=$(${lib.getExe pkgs.tmux} display-message -p -t "$session_id" '#{pane_id}')
          printf 'session\t%s\t%s\t%s\t%s\n' \
            "$session_id" "$session_pane" "$session_id" "$session_name"

          window_ids=$(${lib.getExe pkgs.tmux} list-windows -t "$session_id" -F '#{window_id}')
          window_count=$(printf '%s\n' "$window_ids" | ${pkgs.coreutils}/bin/wc -l | tr -d ' ')
          window_number=0
          for window_id in $window_ids; do
            window_number=$((window_number + 1))
            if [ "$window_number" -eq "$window_count" ]; then
              connector='└─'
            else
              connector='├─'
            fi
            pane_id=$(${lib.getExe pkgs.tmux} display-message -p -t "$window_id" '#{pane_id}')
            window_label=$(${lib.getExe pkgs.tmux} display-message -p -t "$window_id" '#{window_index}: #{window_name}')
            printf 'window\t%s\t%s\t%s\t  %s %s\n' \
              "$window_id" "$pane_id" "$session_id" "$connector" "$window_label"
          done
        done
      } | ${lib.getExe pkgs.fzf} --no-sort --reverse --prompt="session/window> " \
        --delimiter='\t' --with-nth=5.. \
        --preview "${lib.getExe pkgs.tmux} capture-pane -e -p -t {3}" \
        --preview-window "right:80%"
    ) || exit 0
    [ -n "$selected" ] || exit 0

    kind=$(printf '%s' "$selected" | cut -f1)
    target_id=$(printf '%s' "$selected" | cut -f2)
    session_id=$(printf '%s' "$selected" | cut -f4)
    if [ "$kind" = window ]; then
      ${lib.getExe pkgs.tmux} select-window -t "$target_id"
    fi
    ${lib.getExe pkgs.tmux} switch-client -t "$session_id"
  '';
  # Resolve or create a worktree outside the picker popup, then open it in the
  # repository session and switch the client that started the operation.
  tmux-wt-open = pkgs.writeShellScript "tmux-wt-open" ''
    set -eu
    client_name=$1
    repodir=$2
    kind=$3
    key=$4

    case "$kind" in
      wt)
        target="$key"
        window_name="$key" ;;
      pr)
        target="pr:$key"
        window_name="#$key" ;;
      *) exit 0 ;;
    esac

    # Use fish so the worktrunk wrapper can apply PR-number worktree paths.
    if ! result=$(
      cd "$repodir"
      ${lib.getExe pkgs.fish} -c 'wt switch --no-cd --format json $argv[1]' -- "$target" 2>/dev/null
    ); then
      ${lib.getExe pkgs.tmux} display-message -c "$client_name" "Worktrunk failed for $target"
      exit 1
    fi
    worktree_path=$(printf '%s\n' "$result" | ${lib.getExe pkgs.jq} -r '.path // empty')
    if [ -z "$worktree_path" ]; then
      ${lib.getExe pkgs.tmux} display-message -c "$client_name" "Worktrunk returned no path for $target"
      exit 1
    fi

    # Match by the canonical repository path. Session names can change when an
    # agent needs attention, so names are not stable identifiers.
    repodir=$(cd "$repodir" && pwd -P)
    session_id=$(
      ${lib.getExe pkgs.tmux} list-sessions -F '#{session_id} #{session_path}' \
        | while read -r id path; do
            canonical=$(cd "$path" 2>/dev/null && pwd -P) || continue
            if [ "$canonical" = "$repodir" ]; then
              printf '%s\n' "$id"
              break
            fi
          done
    )

    if [ -n "$session_id" ]; then
      window_id=$(${lib.getExe pkgs.tmux} new-window -d -P -F '#{window_id}' \
        -t "$session_id:" -n "$window_name" -c "$worktree_path")
    else
      # No repository session: create it with the worktree as its only window.
      # `new-session -c` sets session_path to the repository so later runs
      # match it; the initial window it creates is replaced by the worktree one.
      session_name=$(basename "$repodir" | tr '.:' '--')
      candidate="$session_name"
      suffix=2
      while ${lib.getExe pkgs.tmux} has-session -t "=$candidate" 2>/dev/null; do
        candidate="$session_name-$suffix"
        suffix=$((suffix + 1))
      done
      initial_window=$(${lib.getExe pkgs.tmux} new-session -d -P -F '#{window_id}' \
        -s "$candidate" -c "$repodir")
      session_id=$(${lib.getExe pkgs.tmux} display-message -p -t "$initial_window" '#{session_id}')
      window_id=$(${lib.getExe pkgs.tmux} new-window -d -P -F '#{window_id}' \
        -t "$session_id:" -n "$window_name" -c "$worktree_path")
      ${lib.getExe pkgs.tmux} kill-window -t "$initial_window"
    fi
    ${lib.getExe pkgs.tmux} set-option -w -t "$window_id" automatic-rename off
    ${lib.getExe pkgs.tmux} select-window -t "$window_id"
    ${lib.getExe pkgs.tmux} switch-client -c "$client_name" -t "$session_id"
  '';
  # Pick a zoxide entry below ~/dev, then pick either an existing worktree or
  # an open PR (most-recently-updated first). The picker starts tmux-wt-open as
  # a background tmux job and closes before Worktrunk runs. Each fzf line carries
  # two hidden fields (kind, key) ahead of the displayed columns.
  tmux-wt-switch = pkgs.writeShellScript "tmux-wt-switch" ''
    set -eu
    dev="$HOME/dev"

    repo=$(${lib.getExe pkgs.zoxide} query -l --base-dir "$dev" --exclude "$dev" \
      | sed "s|^$dev/||" \
      | ${lib.getExe pkgs.fzf} --no-sort --reverse --scheme=path --prompt="repo> ") || exit 0
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

    case "$kind" in wt | pr) ;; *) exit 0 ;; esac

    client_name=$(${lib.getExe pkgs.tmux} display-message -p '#{client_name}')
    command=$(printf '%q %q %q %q %q' \
      "${tmux-wt-open}" "$client_name" "$repodir" "$kind" "$key")
    ${lib.getExe pkgs.tmux} run-shell -b "$command"
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
  tmux-pi-dispatch = pkgs.writeShellScript "tmux-pi-dispatch" ''
    set -eu
    root="$HOME/dev/agents"
    mkdir -p "$root/worktrees" "$root/sessions"

    base="dispatch-$(${pkgs.coreutils}/bin/date +%m%d-%H%M%S)"
    name="$base"
    suffix=2
    while ${lib.getExe pkgs.tmux} has-session -t "=$name" 2>/dev/null; do
      name="$base-$suffix"
      suffix=$((suffix + 1))
    done

    session_id=$(${lib.getExe pkgs.tmux} new-session -d -P -F '#{session_id}' \
      -s "$name" -c "$root" "${lib.getExe pkgs.pi-coding-agent} --approve --name '$name'")
    ${lib.getExe pkgs.tmux} switch-client -t "$session_id"
  '';
  tmux-last-session = pkgs.writeShellScript "tmux-last-session" ''
    current="$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')"

    # tmux can retain a deleted session as the last-session target. Prefer its
    # history, then select the most recently attached session that still exists.
    if ${lib.getExe pkgs.tmux} switch-client -l 2>/dev/null; then
      exit 0
    fi

    target=$(
      ${lib.getExe pkgs.tmux} list-sessions -F '#{?session_last_attached,#{session_last_attached},0} #{session_name}' \
        | ${pkgs.coreutils}/bin/sort -rn -k1,1 \
        | while read -r _ candidate; do
            if [ "$candidate" != "$current" ]; then
              printf '%s\n' "$candidate"
              break
            fi
          done
    )
    [ -n "$target" ] || exit 1
    ${lib.getExe pkgs.tmux} switch-client -t "=$target"
  '';
  tmux-kill-session = pkgs.writeShellScript "tmux-kill-session" ''
    target=$1
    ${tmux-last-session} || exit 0
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

      # Splits and new windows should inherit the active pane's cwd.
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

      # Pick a repo, then open a worktree or PR as a repository-session window.
      unbind w
      bind w display-popup -h 80% -w 80% -E "${tmux-wt-switch}"

      # Pick a repo, create a tfm/<name> branch and worktree, then open/attach
      # its tmux session through the `wts` fish function.
      bind -N "new tfm worktree" b display-popup -h 80% -w 80% -E "${tmux-wt-create}"

      # Start a unique, repo-less pi dispatcher session. It can run asynchronous
      # agents in shared worktrees without registering the session with sesh.
      bind -N "new pi dispatcher" M run-shell "${tmux-pi-dispatch}"

      # Pick any window in any session, with a live pane preview.
      bind W display-popup -h 90% -w 90% -E "${tmux-window-picker}"

      # Switch to the last existing session. If tmux's last-session target was
      # deleted, use the most recently attached session that still exists.
      bind -N "last session" Tab run-shell "${tmux-last-session}"

      # Remove the old duplicate last-session binding, including after reload.
      unbind a

      # From a worktrunk worktree session (…/repo/.worktrees/branch), jump to the
      # session for the repository itself. `sesh connect --root <path>` resolves
      # the git worktree/repository root of that path and connects to its
      # session, creating it when it does not exist. `$(pwd)` is the pane's
      # directory: `run-shell` runs the command in the pane's working directory.
      # `m` is tmux's `select-pane -m` (mark pane) by default, which this
      # replaces.
      unbind m
      bind -N "root session (via sesh)" m run-shell "sesh connect --root #{q:pane_current_path}"

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
