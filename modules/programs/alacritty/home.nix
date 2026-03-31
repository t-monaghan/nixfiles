{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.alacritty.enable {
  programs.alacritty = {
    enable = true;
    settings = {
      selection = {
        save_to_clipboard = true;
      };
      window = {
        option_as_alt = "Both";
        decorations = "buttonless";
        opacity = 0.75;
        blur = true;
        dimensions = {
          columns = 100;
          lines = 32;
        };
        dynamic_padding = true;
      };
      font.normal = {
        family = "Jetbrains Mono";
        style = "Regular";
      };
      font.size = 16.0;
      # Tomorrow Night Eighties
      colors = {
        bright = {
          black = "#000000";
          blue = "#6699cc";
          cyan = "#66cccc";
          green = "#99cc99";
          magenta = "#cc99cc";
          red = "#f2777a";
          white = "#ffffff";
          yellow = "#ffcc66";
        };
        cursor = {
          cursor = "#cccccc";
          text = "#2d2d2d";
        };
        normal = {
          black = "#000000";
          blue = "#6699cc";
          cyan = "#66cccc";
          green = "#99cc99";
          magenta = "#cc99cc";
          red = "#f2777a";
          white = "#ffffff";
          yellow = "#ffcc66";
        };
        primary = {
          background = "#2d2d2d";
          foreground = "#cccccc";
        };
        selection = {
          background = "#515151";
          text = "#cccccc";
        };
      };
      mouse.hide_when_typing = true;
      scrolling.multiplier = 2;
    };
  };
}
