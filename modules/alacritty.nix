{
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
      family = "UDEV Gothic 35NF";
      style = "Regular";
    };
    font.size = 16.0;
    colors = builtins.fromTOML (builtins.readFile ../dots/alacritty-colors.toml);
    mouse.hide_when_typing = true;
    scrolling.multiplier = 2;
  };
}
