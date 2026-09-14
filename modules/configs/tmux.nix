# Colours here name ANSI slots rather than hex values, so they follow the
# terminal's palette — which Ghostty sets per appearance mode from
# ./colours.nix. tmux doesn't participate in system light/dark switching itself,
# so this is what makes the pane border readable in both modes:
#
#   yellow / cyan / brightblack   base0A / base0C / base03
#   white                         base05, the default foreground
#   colour16                      base09, orange (no ANSI equivalent)
#   colour18                      base01, the lighter background
{
  pkgs,
  lib,
  ...
}: let
  # Generate custom prefix bindings and the prefix menu from the same data so
  # their keys, descriptions, and commands stay consistent. Entries without
  # `bind = true` document useful default tmux bindings without replacing them.
  tmuxMenuEntries = [
    {section = "Sessions";}
    {
      key = "s";
      label = "sesh picker";
      command = ''display-popup -E -w 80% -h 80% "sesh picker -i"'';
      bind = true;
    }
    {
      key = "w";
      label = "worktree / PR picker";
      command = ''display-popup -h 80% -w 80% -E "${tmux-wt-switch}"'';
      bind = true;
    }
    {
      key = "b";
      label = "new tfm worktree";
      command = ''display-popup -h 80% -w 80% -E "${tmux-wt-create}"'';
      bind = true;
    }
    {
      key = "m";
      label = "main worktree window";
      command = ''run-shell "${tmux-main-window} #{q:pane_id} #{q:pane_current_path}"'';
      bind = true;
    }
    {
      key = "a";
      label = "last session";
      command = ''run-shell "${tmux-last-session}"'';
      bind = true;
    }
    {
      key = "Tab";
      menuKey = "";
      label = "last window or session";
      command = ''if -F '#{e|>:#{session_windows},1}' 'last-window' 'run-shell "${tmux-last-session}"' '';
      bind = true;
    }
    {
      key = "X";
      label = "kill session, go to last";
      command = ''if -F '#{e|>:#{server_sessions},1}' 'run-shell "${tmux-kill-session} #{q:session_name}"' ""'';
      bind = true;
    }
    {
      key = "M";
      label = "new pi dispatcher";
      command = ''run-shell "${tmux-pi-dispatch}"'';
      bind = true;
    }
    {
      key = "g";
      label = "clone GitHub repo";
      command = ''command-prompt -p "Clone GitHub repo ([org/]repo [dir]):" "run-shell -b 'tmux display-message \"Cloning %1...\" && fish -c \"ghclone %1\"'"'';
      bind = true;
    }

    {section = "Windows / panes";}
    {
      key = "W";
      label = "window picker (all sessions)";
      command = ''display-popup -h 90% -w 90% -E "${tmux-window-picker}"'';
      bind = true;
    }
    {
      key = "c";
      label = "new window (cwd)";
      command = ''new-window -c '#{pane_current_path}' '';
      bind = true;
    }
    {
      key = ''"'';
      label = "split below (cwd)";
      command = ''split-window -v -c '#{pane_current_path}' '';
      bind = true;
    }
    {
      key = "%";
      label = "split right (cwd)";
      command = ''split-window -h -c '#{pane_current_path}' '';
      bind = true;
    }

    {section = "Useful defaults";}
    {
      key = "z";
      label = "zoom pane";
      command = "resize-pane -Z";
    }
    {
      key = "[";
      label = "copy mode";
      command = "copy-mode";
    }
    {
      key = "d";
      label = "detach client";
      command = "detach-client";
    }
    {
      key = ",";
      label = "rename window";
      command = ''command-prompt -I "#W" { rename-window "%%" }'';
    }
    {
      key = "$";
      label = "rename session";
      command = ''command-prompt -I "#S" { rename-session "%%" }'';
    }
    {
      key = "x";
      label = "kill pane";
      command = ''confirm-before -p "kill-pane #P? (y/n)" kill-pane'';
    }
    {
      key = "{";
      label = "swap pane up";
      command = "swap-pane -U";
    }
    {
      key = "}";
      label = "swap pane down";
      command = "swap-pane -D";
    }
  ];
  tmuxMenuBindings = lib.concatMapStringsSep "\n" (entry:
    lib.optionalString (entry.bind or false)
    "bind -N ${lib.escapeShellArg entry.label} ${lib.escapeShellArg entry.key} ${entry.command}")
  tmuxMenuEntries;
  tmuxMenuItems = lib.concatMapStringsSep " " (entry:
    if entry ? section
    then lib.concatMapStringsSep " " lib.escapeShellArg ["-#[bold]${entry.section}" "" ""]
    else
      lib.concatMapStringsSep " " lib.escapeShellArg [
        "${entry.label}  (${entry.key})"
        (entry.menuKey or entry.key)
        entry.command
      ])
  tmuxMenuEntries;

  # List each tmux session as a parent row followed by its window rows. Hidden
  # stable IDs drive selection and previews. Window rows include the session
  # name for filtering. They show an explicit PR or branch window name, or use
  # the active pane title when tmux controls the window name.
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
            window_label=$(${lib.getExe pkgs.tmux} display-message -p -t "$window_id" \
              '#{session_name} / #{window_index}: #{?automatic-rename,#{?pane_title,#{pane_title},#{window_name}},#{window_name}}')
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
  tmux-main-window = pkgs.writeShellScript "tmux-main-window" ''
    set -eu
    pane_id=$1
    pane_path=$2
    session_id=$(${lib.getExe pkgs.tmux} display-message -p -t "$pane_id" '#{session_id}')

    main_path=$(${lib.getExe pkgs.git} -C "$pane_path" worktree list --porcelain \
      | ${pkgs.gawk}/bin/awk '/^worktree / { sub(/^worktree /, ""); print; exit }')
    [ -n "$main_path" ] || exit 0

    window_id=$(
      ${lib.getExe pkgs.tmux} list-windows -t "$session_id" -F '#{window_id}\t#{pane_current_path}' \
        | while IFS="$(printf '\t')" read -r candidate path; do
            worktree=$(${lib.getExe pkgs.git} -C "$path" rev-parse --show-toplevel 2>/dev/null) || continue
            if [ "$worktree" = "$main_path" ]; then
              printf '%s\n' "$candidate"
              break
            fi
          done
    )

    if [ -z "$window_id" ]; then
      window_name=$(${lib.getExe pkgs.git} -C "$main_path" branch --show-current)
      [ -n "$window_name" ] || window_name=main
      window_id=$(${lib.getExe pkgs.tmux} new-window -d -P -F '#{window_id}' \
        -t "$session_id:" -n "$window_name" -c "$main_path")
      ${lib.getExe pkgs.tmux} set-option -w -t "$window_id" automatic-rename off
    fi

    active_window=$(${lib.getExe pkgs.tmux} display-message -p -t "$session_id" '#{window_id}')
    if [ "$active_window" != "$window_id" ]; then
      ${lib.getExe pkgs.tmux} select-window -t "$window_id"
    fi
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
      set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{?#{m:\[*,#{session_name}},#[fg=yellow]#{session_name}#[default],#{session_name}},#{pane_title}} #{?window_zoomed_flag, #[fg=cyan bold][ZOOMED]#[default],}#{?#{==:#{pane_index},0},#[align=right]#{S:#[default]─ #{?session_attached,#{?#{m:\[*,#{session_name}},#[fg=colour16],#[fg=white bold]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#{?#{m:\[*,#{session_name}},#[fg=yellow],#[fg=brightblack]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}#[default]──,}'
      bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
      bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

      # Vim-style visual selection in copy mode
      bind -Tcopy-mode-vi v send -X begin-selection
      bind -Tcopy-mode-vi y send -X copy-selection-and-cancel

      # Highlight the active pane while the prefix table is active. The format
      # avoids starting a shell and a sleeping process for each prefix press.
      set -g window-active-style 'bg=#{?client_prefix,colour18,default}'
      bind -Troot C-b switch-client -Tprefix

      # Replace selected default bindings and generate the same entries in the
      # custom prefix menu. Keep the full tmux note list available on `/`.
      unbind s
      unbind w
      unbind m
      ${tmuxMenuBindings}
      bind -N "custom key menu" ? display-menu -T "#[align=centre] tmux " -x C -y C -- ${tmuxMenuItems}
      bind -N "all key bindings" / list-keys -N -T prefix

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
