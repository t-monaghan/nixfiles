{
  pkgs,
  lib,
  colors,
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
  # Pick a repo from ~/dev, pick one of its open PRs (most-recently-updated
  # first), and open/attach a session that runs `wt switch pr:<n>` in it.
  tmux-pr-switch = pkgs.writeShellScript "tmux-pr-switch" ''
    set -eu
    dev="$HOME/dev"

    repo=$(${pkgs.findutils}/bin/find "$dev" -maxdepth 1 -mindepth 1 -type d \
        -exec test -e '{}/.git' ';' -print \
      | sed "s|$dev/||" | sort \
      | ${lib.getExe pkgs.fzf} --reverse --prompt="repo> ") || exit 0
    [ -n "$repo" ] || exit 0
    repodir="$dev/$repo"

    prs=$(cd "$repodir" && ${lib.getExe pkgs.gh} pr list --state open --limit 50 \
      --json number,title,updatedAt,author,headRefName 2>/dev/null) || {
        ${lib.getExe pkgs.tmux} display-message "gh pr list failed in $repo"; exit 1; }

    line=$(printf '%s' "$prs" | ${lib.getExe pkgs.jq} -r '
        sort_by(.updatedAt) | reverse | .[]
        | "#\(.number)\t\(.updatedAt[0:10])\t@\(.author.login)\t\(.title)"' \
      | ${lib.getExe pkgs.fzf} --reverse --delimiter='\t' --with-nth=1,2,3,4 \
          --prompt="pr ($repo)> ") || exit 0
    [ -n "$line" ] || exit 0

    num=$(printf '%s' "$line" | cut -f1 | tr -d '#')
    [ -n "$num" ] || exit 0

    sess="$(printf '%s' "$repo" | tr './:' '-')-$num"
    if ! ${lib.getExe pkgs.tmux} has-session -t "=$sess" 2>/dev/null; then
      ${lib.getExe pkgs.tmux} new-session -d -s "$sess" -c "$repodir"
      ${lib.getExe pkgs.tmux} send-keys -t "$sess" "wt switch pr:$num" Enter
    fi
    ${lib.getExe pkgs.tmux} switch-client -t "$sess"
  '';
  tmux-kill-session = pkgs.writeShellScript "tmux-kill-session" ''
    count=$(${lib.getExe pkgs.tmux} list-sessions | wc -l)
    [ "$count" -le 1 ] && exit 0
    target=$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')
    sesh last 2>/dev/null || ${lib.getExe pkgs.tmux} switch-client -n
    ${lib.getExe pkgs.tmux} kill-session -t "$target"
  '';
in {
  enable = true;
  mouse = true;
  escapeTime = 100;
  keyMode = "vi";
  customPaneNavigationAndResize = true;
  historyLimit = 50000;
  terminal = "screen-256color";
  extraConfig = ''
    set -g status off
    set -g detach-on-destroy off
    set -g pane-border-status top
    set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{?#{m:\[*,#{session_name}},#[fg=${colors.warn}]#{session_name}#[default],#{session_name}},#{pane_title}} #{?window_zoomed_flag, #[fg=${colors.accent_alt} bold][ZOOMED]#[default],}#{?#{==:#{pane_index},0},#[align=right]#{S:#[default]─ #{?session_attached,#{?#{m:\[*,#{session_name}},#[fg=${colors.orange}],#[fg=brightblack]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#{?#{m:\[*,#{session_name}},#[fg=${colors.warn}],#[fg=${colors.tmux.active}]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}#[default]──,}'
    bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
    bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

    # Vim-style visual selection in copy mode
    bind -Tcopy-mode-vi v send -X begin-selection
    bind -Tcopy-mode-vi y send -X copy-selection-and-cancel

    # Highlight active pane background when prefix is pressed
    bind -Troot C-b select-pane -P 'bg=${colors.bg1}' \; switch-client -Tprefix \; run -b 'sleep 1 && tmux select-pane -P bg=default'

    # Open sesh picker instead of default session tree
    unbind s
    bind s display-popup -E -w 50 -h 18 "sesh list -i | ${lib.getExe pkgs.fzf} --height=100% --no-sort --reverse --ansi | xargs -r sesh connect"

    # Pick a repo + PR and open/attach a `wt switch pr:<n>` session
    unbind w
    bind w display-popup -h 80% -w 80% -E "${tmux-pr-switch}"

    # Switch windows via fzf picker (only if multiple windows)
    bind W if -F '#{?#{e|>:#{session_windows},1},1,}' 'display-popup -h 90% -w 90% -E "${tmux-window-picker}"' ""

    # Jump to last (MRU) window, or fall back to last session when there's only one window.
    # `l` is taken by pane navigation, so use Tab.
    bind -N "last-window-or-session" Tab if -F '#{?#{e|>:#{session_windows},1},1,}' 'last-window' 'switch-client -l'

    # Last session via sesh (only if multiple sessions)
    bind -N "last-session (via sesh)" a if-shell '[ $(tmux list-sessions | wc -l) -gt 1 ]' "run-shell 'sesh last'"

    # Kill current session and switch to previous
    bind X run-shell '${tmux-kill-session}'

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
}
