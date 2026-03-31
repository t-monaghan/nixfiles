{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.atuin.enable {
  programs.atuin = {
    enable = true;
    # there is an issue where atuin creates a config file in shell hook: https://github.com/nix-community/home-manager/issues/5734
    # workaround is to remove the default config file and run hm switch in sh
    settings = {
      # inline_height = 10;
      enter_accept = true;
      filter_mode_shell_up_key_binding = "session";
      workspaces = true;
    };
  };
}
