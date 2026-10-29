{
  config,
  lib,
  colors,
  fonts,
  ...
}: let
  # Alacritty has no system-appearance hook, so it takes the dark palette.
  palette = colors.palettes.dark;
in
  lib.mkIf config.nixfiles.context.role.desktop {
    programs.alacritty = {
      enable = true;
      settings = {
        selection.save_to_clipboard = true;
        window = {
          opacity = 0.95;
          blur = true;
          decorations = "buttonless";
          dimensions = {
            columns = 100;
            lines = 50;
          };
        };
        font = {
          normal.family = fonts.mono;
          size = fonts.size;
        };
        colors = {
          primary = {
            background = palette.base00;
            foreground = palette.base05;
          };
          normal = {
            black = palette.base00;
            red = palette.base08;
            green = palette.base0B;
            yellow = palette.base0A;
            blue = palette.base0D;
            magenta = palette.base0E;
            cyan = palette.base0C;
            white = palette.base06;
          };
          bright = {
            black = palette.base03;
            red = palette.base08;
            green = palette.base0B;
            yellow = palette.base0A;
            blue = palette.base0D;
            magenta = palette.base0E;
            cyan = palette.base0C;
            white = palette.base07;
          };
        };
        mouse.hide_when_typing = true;
        scrolling.multiplier = 2;
      };
    };
  }
