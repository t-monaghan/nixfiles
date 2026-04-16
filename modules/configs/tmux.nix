{
  pkgs,
  lib,
  ...
}: let
  tmux-window-picker = pkgs.writeShellScript "tmux-window-picker" ''
    session="$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')"
    selected=$(${lib.getExe pkgs.tmux} list-windows -t "$session" -F '#{window_index}: #{pane_title}' \
      | ${lib.getExe pkgs.fzf} --no-sort --reverse --delimiter=':' \
        --preview "${lib.getExe pkgs.tmux} capture-pane -e -p -t $session:{1}" \
        --preview-window "right:80%")
    [ -n "$selected" ] && ${lib.getExe pkgs.tmux} select-window -t "$session:''${selected%%:*}"
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
    set -g pane-border-status top
    set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{?#{m:\[*,#{session_name}},#[fg=brightyellow]#{session_name}#[default],#{session_name}},#{pane_title}}#{?window_zoomed_flag, #[fg=cyan bold][ZOOMED]#[default],}#{?#{==:#{pane_index},0},#[align=right]#{S:#[default]─ #{?session_attached,#{?#{m:\[*,#{session_name}},#[fg=brightyellow],#[fg=green]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#{?#{m:\[*,#{session_name}},#[fg=brightyellow],#[dim]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}#[default]──,}'
    bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
    bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

    # Vim-style visual selection in copy mode
    bind -Tcopy-mode-vi v send -X begin-selection
    bind -Tcopy-mode-vi y send -X copy-selection-and-cancel

    set -g window-style 'bg=colour236'
    set -g window-active-style 'bg=terminal'

    # Highlight active pane background when prefix is pressed
    bind -Troot C-b select-pane -P 'bg=colour235' \; switch-client -Tprefix \; run -b 'sleep 1 && tmux select-pane -P bg=default'

    # Open sesh picker instead of default session tree
    unbind s
    bind s display-popup -E -w 50 -h 18 "sesh list -i | ${lib.getExe pkgs.fzf} --height=100% --no-sort --reverse --ansi | xargs -r sesh connect"

    # Switch windows via gum (only if multiple windows)
    unbind w
    bind w if -F '#{?#{e|>:#{session_windows},1},1,}' 'display-popup -h 90% -w 90% -E "${tmux-window-picker}"' ""

    # Last session via sesh (only if multiple sessions)
    bind -N "last-session (via sesh)" a if-shell '[ $(tmux list-sessions | wc -l) -gt 1 ]' "run-shell 'sesh last'"

    # Kill current session and switch to previous
    bind X run-shell 'target="$(tmux display-message -p "#{session_name}")" && tmux switch-client -p && tmux kill-session -t "$target"'

    # Clone GitHub repo and open session
    bind g command-prompt -p "Clone GitHub repo ([org/]repo [dir]):" "run-shell -b 'tmux display-message \"Cloning %1...\" && fish -c \"ghclone %1\"'"

    # Clear Claude notifications when switching to a session
    set-hook -g after-select-window 'run-shell "session=$$(tmux display-message -p \"#{session_name}\"); case $$session in \\[*) tmux rename-session \"$$(echo $$session | cut -c2-)\" ;; esac"'
    set-hook -g client-session-changed 'run-shell "session=$$(tmux display-message -p \"#{session_name}\"); case $$session in \\[*) tmux rename-session \"$$(echo $$session | cut -c2-)\" ;; esac"'
  '';
}
