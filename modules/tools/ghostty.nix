{
  colors,
  fonts,
  lib,
  ...
}: let
  # A Ghostty theme file built from one of our palettes. Ghostty resolves theme
  # names against $XDG_CONFIG_HOME/ghostty/themes, so these are our own files,
  # not upstream themes — the name is a filename, not a choice of colours.
  #
  # `palette` entries are "<index>=<hex>"; home-manager writes the list as
  # repeated `palette = …` lines. The index order is base16's, defined once in
  # ./colours.nix, and is what lets bat, fish, tmux and starship follow the mode.
  mkTheme = p: {
    background = p.base00;
    foreground = p.base05;
    cursor-color = p.base05;
    selection-background = p.base02;
    selection-foreground = p.base05;
    palette = lib.imap0 (i: hex: "${toString i}=${hex}") (colors.terminalPalette p);
  };
in {
  programs.ghostty = {
    enable = true;
    package = null;
    enableFishIntegration = true;

    themes = {
      nixfiles-dark = mkTheme colors.palettes.dark;
      nixfiles-light = mkTheme colors.palettes.light;
    };

    settings = {
      auto-update = "download";
      auto-update-channel = "stable";

      keybind = "global:ctrl+grave_accent=toggle_secure_input";

      confirm-close-surface = false;
      quit-after-last-window-closed = true;

      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      copy-on-select = "clipboard";

      theme = "light:nixfiles-light,dark:nixfiles-dark";
      cursor-style = "block";
      cursor-invert-fg-bg = true;
      cursor-opacity = 0.7;
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
      background-opacity = 0.90;
      background-opacity-cells = true;
      background-blur = 20;
      font-family = fonts.mono;
      font-size = fonts.size;
      font-thicken = true;
      font-thicken-strength = 255;
      font-feature = "+zero,-liga,-calt";
      adjust-cell-height = "10%";

      macos-option-as-alt = "right";
      macos-titlebar-style = "hidden";
      macos-icon = "xray";
      macos-icon-frame = "plastic";
      shell-integration = "fish";
      shell-integration-features = "no-cursor";

      window-padding-x = 2;
      window-padding-y = 2;
      window-padding-balance = true;

      quick-terminal-position = "right";
      quick-terminal-animation-duration = 0;

      resize-overlay = "never";
    };
  };
}
