{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.tmux.enable {
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
      set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{session_name},#{pane_title}}#{?#{==:#{pane_index},0},#[align=right]#{S:#{?session_attached,#[fg=green]─ #{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#[dim]─ #{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}/#{session_windows},} #[default]}}──,}'
      bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
      bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

      # Highlight active pane background when prefix is pressed
      bind -Troot C-b select-pane -P 'bg=colour235' \; switch-client -Tprefix \; run -b 'sleep 1 && tmux select-pane -P bg=default'
    '';
  };
}
