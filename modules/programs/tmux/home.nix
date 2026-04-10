{
  config,
  lib,
  pkgs,
  ...
}: let
  tmux-window-picker = pkgs.writeShellScript "tmux-window-picker" ''
    selected=$(tmux list-windows -F '#{window_index}: #{pane_title}' \
      | gum filter --limit 1 --no-sort --fuzzy --placeholder 'Pick a window')
    [ -n "$selected" ] && tmux select-window -t "''${selected%%:*}"
  '';
in
  lib.mkIf config.nixfiles.programs.tmux.enable {
    home.packages = [pkgs.gum];

    programs.tmux = {
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
        set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{session_name},#{pane_title}}#{?#{==:#{pane_index},0},#[align=right]#{S:#{?session_attached,#[fg=green]─ #{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#[dim]─ #{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}──,}'
        bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
        bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

        set -g window-style 'bg=colour236'
        set -g window-active-style 'bg=terminal'

        # Highlight active pane background when prefix is pressed
        bind -Troot C-b select-pane -P 'bg=colour235' \; switch-client -Tprefix \; run -b 'sleep 1 && tmux select-pane -P bg=default'

        # Open sesh picker instead of default session tree
        unbind s
        bind s display-popup -h 30% -w 50% -E "sesh picker -i"

        # Switch windows via gum (only if multiple windows)
        unbind w
        bind w if -F '#{e|>:#{session_windows},1}' 'display-popup -h 10% -w 50% -E "${tmux-window-picker}"' ""

        # Last session via sesh
        bind -N "last-session (via sesh)" a run-shell "sesh last"
      '';
    };
  }
