{config, lib, ...}:
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
      set -g status on
      set -g status-style bg=default
      set -g status-left ""
      set -g status-right "#[fg=green]#S"
      set -g status-right-length 50
      set -g window-status-current-format ""
      set -g window-status-format ""
      bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
      bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down'';
  };
}
