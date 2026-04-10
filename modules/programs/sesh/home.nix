{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.sesh.enable {
  # TODO: add `ls ~/dev` (diff zoxide) to sesh selector
  programs.sesh = {
    enable = true;
    enableAlias = false; # saves 's' alias for sesh's television channel
    enableTmuxIntegration = false; # handled in tmux module
    settings = {
      default_session = {
        preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
      };
    };
  };
}
