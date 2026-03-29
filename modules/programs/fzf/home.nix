{config, lib, ...}:
lib.mkIf config.nixfiles.programs.fzf.enable {
  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;
  };
}
