{
  enable = true;
  settings = {
    window = {
      option_as_alt = "Both";

      decorations = "buttonless";
      opacity = 0.65;
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
    font.size = 17.0;
    colors = builtins.fromTOML (builtins.readFile ../dots/alacritty-colors.toml);
  };
}
