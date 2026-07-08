# Unified colorscheme module
#
# Central palette definition consumed by all program configs.
#
# Defines:
#   - A base16 palette subset (base00, base03, base05–base08, base0A–base0E)
#   - Semantic aliases (bg1, accent, accent_alt, warn, error, info, ok, orange)
#   - Per-program theme names (nixvim, ghostty, zed, bat)
#
{
  # --- base16 palette ---
  base00 = "#2b3339"; # bg
  base03 = "#868d80"; # grey
  base05 = "#d3c6aa"; # fg
  base06 = "#e9e8d2"; # fg bright
  base07 = "#fff9e8"; # fg brightest
  base08 = "#e67e80"; # red
  base0A = "#dbbc7f"; # yellow
  base0B = "#a7c080"; # green
  base0C = "#83c092"; # aqua
  base0D = "#7fbbb3"; # blue
  base0E = "#d699b6"; # purple

  # --- semantic aliases ---
  bg1 = "#323c41";
  accent = "#a7c080"; # green – the signature Everforest accent
  accent_alt = "#83c092"; # aqua
  warn = "#dbbc7f"; # yellow
  error = "#e67e80"; # red
  info = "#7fbbb3"; # blue
  ok = "#a7c080"; # green
  orange = "#e69875";

  # --- per-program theme names ---
  nixvim = {dark = "base16-everforest-dark-hard"; light = "monokai-pro-light";};
  ghostty = {dark = "Everforest Dark Hard"; light = "Monokai Pro Light";};
  zed = {dark = "Everforest Dark"; light = "Monokai Pro Light";};
  bat = {dark = "gruvbox-dark"; light = "Monokai Extended Light";};
}
