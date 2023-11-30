{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tom.monaghan";
  home.homeDirectory = "/Users/tom.monaghan";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bat.enable = true;
  programs.zsh.enableCompletion = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    themes = {
      tmonaghan = let
        transparent = "none"; 
      in {
        inherits = "acme";
        "ui.background" = transparent;
        "ui.bufferline.active" = { fg = "#e69875";};
      };
    };
    settings = {
      theme = "tmonaghan"; # This should be tmonaghan for darwin, with transparent bg
      editor = {
        line-number = "relative";
        bufferline = "always";
        true-color = true;
      };      
      editor.statusline = {      
        left = ["spacer" "version-control" "position" "mode" "diagnostics"];
        right = ["workspace-diagnostics" "file-name" "spinner"];
      };
      keys.insert = {
        j.k = "normal_mode";
        C-l = ["goto_line_end" ":append-output echo -n ';'" "normal_mode"];
      };
    };
  };
}
