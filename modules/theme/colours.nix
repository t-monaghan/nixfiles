# Unified colour palette — used by ALL three machines.
#
# Two palettes, one per appearance mode. Every program derives its colours from
# these; no program is handed the name of a theme it did not get from here.
# Editing a hex value below changes Neovim, Ghostty, bat, Zed, fish, tmux and
# starship together, on every machine.
#
# Each palette is a complete base16 scheme: exactly the 16 slots base00–base0F,
# with the roles fixed by the base16 specification (see the comments). Semantic
# aliases (`accent`, `warn`, `error`, …) used to sit alongside them, but they
# only ever restated a slot — `accent` and `ok` were both `base0B` — so
# consumers now name the slot directly.
#
# How each program gets these values:
#
#   Generated theme files, one per mode
#     ghostty  ./ghostty.nix   → $XDG_CONFIG_HOME/ghostty/themes/nixfiles-{dark,light}
#     zed      ./zed.nix       → $XDG_CONFIG_HOME/zed/themes/nixfiles.json
#     nixvim   ./neovim        → base16-nvim, configured with the slots directly
#
#   Via the terminal's ANSI palette (which ghostty sets from `terminalPalette`
#   below), so they follow the mode with no config of their own
#     bat        `--theme=base16` maps onto ANSI 0–21
#     fish       ANSI colour names (./fish.nix)
#     tmux       ANSI colour names + indices (./tmux.nix)
#     starship   ANSI colour names (./starship.nix)
#
#   Cannot follow the mode (no appearance hook), so they use `palettes.dark`
#     alacritty      a terminal, needs literal hex (../home.nix)
#     jankyborders   macOS window borders (../home.nix)
let
  # Everforest Dark Hard.
  dark = {
    base00 = "#2b3339"; # default background
    base01 = "#323c41"; # lighter background (status bars, line highlight)
    base02 = "#3a454a"; # selection background
    base03 = "#868d80"; # comments, invisibles
    base04 = "#9da9a0"; # dark foreground (status bars)
    base05 = "#d3c6aa"; # default foreground
    base06 = "#e9e8d2"; # light foreground
    base07 = "#fff9e8"; # lightest foreground
    base08 = "#e67e80"; # red — variables, diff deleted
    base09 = "#e69875"; # orange — numbers, constants
    base0A = "#dbbc7f"; # yellow — classes, search background
    base0B = "#a7c080"; # green — strings, diff added
    base0C = "#83c092"; # aqua — escapes, regex
    base0D = "#7fbbb3"; # blue — functions
    base0E = "#d699b6"; # purple — keywords
    base0F = "#9da9a0"; # brown — Everforest has none; grey, as upstream base16 does
  };

  # Solarized Light. base06/base07 are darker than base05 because a light
  # scheme inverts the foreground ramp.
  light = {
    base00 = "#fdf6e3"; # default background
    base01 = "#eee8d5"; # lighter background (status bars, line highlight)
    base02 = "#93a1a1"; # selection background
    base03 = "#839496"; # comments, invisibles
    base04 = "#657b83"; # dark foreground (status bars)
    base05 = "#586e75"; # default foreground
    base06 = "#073642"; # light foreground
    base07 = "#002b36"; # lightest foreground
    base08 = "#dc322f"; # red — variables, diff deleted
    base09 = "#cb4b16"; # orange — numbers, constants
    base0A = "#b58900"; # yellow — classes, search background
    base0B = "#859900"; # green — strings, diff added
    base0C = "#2aa198"; # aqua — escapes, regex
    base0D = "#268bd2"; # blue — functions
    base0E = "#6c71c4"; # purple — keywords
    base0F = "#d33682"; # brown — magenta stands in
  };
in {
  palettes = {inherit dark light;};

  # base16 → terminal colour index, the mapping base16-shell defines and bat's
  # `base16` theme expects. Ghostty writes it into both theme files, so any
  # terminal program that names an ANSI colour instead of a hex value follows
  # the appearance mode for free.
  #
  # 0–7 normal, 8–15 bright, 16–21 the six slots with no ANSI equivalent.
  terminalPalette = p: [
    p.base00 # 0  black
    p.base08 # 1  red
    p.base0B # 2  green
    p.base0A # 3  yellow
    p.base0D # 4  blue
    p.base0E # 5  magenta
    p.base0C # 6  cyan
    p.base05 # 7  white
    p.base03 # 8  bright black
    p.base08 # 9  bright red
    p.base0B # 10 bright green
    p.base0A # 11 bright yellow
    p.base0D # 12 bright blue
    p.base0E # 13 bright magenta
    p.base0C # 14 bright cyan
    p.base07 # 15 bright white
    p.base09 # 16 orange
    p.base0F # 17 brown
    p.base01 # 18 lighter background
    p.base02 # 19 selection background
    p.base04 # 20 dark foreground — mid-tone, readable in BOTH modes
    p.base06 # 21 light foreground
  ];
}
