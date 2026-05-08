# Unified colorscheme module
#
# Central palette definition consumed by all program configs.
# Switch the entire system theme by changing `active` below.
#
# Each scheme defines:
#   - A 16-color terminal palette (base00–base0F, base16 style)
#   - Semantic aliases (bg, fg, accent, warn, error, info, ok)
#   - Per-program theme names where an exact palette isn't used
#
let
  schemes = {
    everforest-dark-hard = {
      # --- base16 palette ---
      base00 = "#2b3339"; # bg
      base01 = "#323c41"; # bg1
      base02 = "#3a454a"; # bg2
      base03 = "#868d80"; # grey
      base04 = "#d3c6aa"; # fg dim
      base05 = "#d3c6aa"; # fg
      base06 = "#e9e8d2"; # fg bright
      base07 = "#fff9e8"; # fg brightest
      base08 = "#e67e80"; # red
      base09 = "#e69875"; # orange
      base0A = "#dbbc7f"; # yellow
      base0B = "#a7c080"; # green
      base0C = "#83c092"; # aqua
      base0D = "#7fbbb3"; # blue
      base0E = "#d699b6"; # purple
      base0F = "#d699b6"; # brown (reuse purple)

      # --- semantic aliases ---
      bg = "#2b3339";
      bg_dim = "#232a2e";
      bg1 = "#323c41";
      bg2 = "#3a454a";
      bg3 = "#475258";
      bg4 = "#4f585e";
      fg = "#d3c6aa";
      fg_dim = "#9da9a0";
      accent = "#a7c080"; # green – the signature Everforest accent
      accent_alt = "#83c092"; # aqua
      warn = "#dbbc7f"; # yellow
      error = "#e67e80"; # red
      info = "#7fbbb3"; # blue
      ok = "#a7c080"; # green
      purple = "#d699b6";
      orange = "#e69875";

      # --- per-program theme names ---
      nixvim = { dark = "base16-everforest-dark-hard"; light = "monokai-pro"; };
      ghostty = { dark = "Everforest Dark Hard"; light = "Monokai Pro Light"; };
      zed = { dark = "Everforest Dark"; light = "Monokai Pro Light"; };
      bat = { dark = "gruvbox-dark"; light = "Monokai Pro Light"; };
    };

    catppuccin-mocha = {
      base00 = "#1e1e2e"; # base
      base01 = "#181825"; # mantle
      base02 = "#313244"; # surface0
      base03 = "#585b70"; # surface2
      base04 = "#bac2de"; # subtext0
      base05 = "#cdd6f4"; # text
      base06 = "#f5e0dc"; # rosewater
      base07 = "#b4befe"; # lavender
      base08 = "#f38ba8"; # red
      base09 = "#fab387"; # peach
      base0A = "#f9e2af"; # yellow
      base0B = "#a6e3a1"; # green
      base0C = "#94e2d5"; # teal
      base0D = "#89b4fa"; # blue
      base0E = "#cba6f7"; # mauve
      base0F = "#f2cdcd"; # flamingo

      bg = "#1e1e2e";
      bg_dim = "#181825";
      bg1 = "#313244";
      bg2 = "#45475a";
      bg3 = "#585b70";
      bg4 = "#6c7086";
      fg = "#cdd6f4";
      fg_dim = "#a6adc8";
      accent = "#89b4fa"; # blue
      accent_alt = "#94e2d5"; # teal
      warn = "#f9e2af"; # yellow
      error = "#f38ba8"; # red
      info = "#89b4fa"; # blue
      ok = "#a6e3a1"; # green
      purple = "#cba6f7";
      orange = "#fab387";

      nixvim = { dark = "catppuccin-mocha"; light = "monokai-pro"; };
      ghostty = { dark = "catppuccin-mocha"; light = "Monokai Pro Light"; };
      zed = { dark = "Catppuccin Mocha"; light = "Monokai Pro Light"; };
      bat = { dark = "Catppuccin Mocha"; light = "Monokai Pro Light"; };
    };

    rose-pine = {
      base00 = "#191724"; # base
      base01 = "#1f1d2e"; # surface
      base02 = "#26233a"; # overlay
      base03 = "#6e6a86"; # muted
      base04 = "#908caa"; # subtle
      base05 = "#e0def4"; # text
      base06 = "#e0def4"; # text
      base07 = "#c4a7e7"; # iris
      base08 = "#eb6f92"; # love
      base09 = "#ebbcba"; # rose
      base0A = "#f6c177"; # gold
      base0B = "#31748f"; # pine
      base0C = "#9ccfd8"; # foam
      base0D = "#c4a7e7"; # iris
      base0E = "#ebbcba"; # rose
      base0F = "#524f67"; # highlight med

      bg = "#191724";
      bg_dim = "#16141f";
      bg1 = "#1f1d2e";
      bg2 = "#26233a";
      bg3 = "#2a283e";
      bg4 = "#393552";
      fg = "#e0def4";
      fg_dim = "#908caa";
      accent = "#c4a7e7"; # iris
      accent_alt = "#9ccfd8"; # foam
      warn = "#f6c177"; # gold
      error = "#eb6f92"; # love
      info = "#c4a7e7"; # iris
      ok = "#31748f"; # pine
      purple = "#c4a7e7";
      orange = "#ebbcba";

      nixvim = { dark = "rose-pine"; light = "monokai-pro"; };
      ghostty = { dark = "rose-pine"; light = "Monokai Pro Light"; };
      zed = { dark = "Rosé Pine"; light = "Monokai Pro Light"; };
      bat = { dark = "gruvbox-dark"; light = "Monokai Pro Light"; };
    };
  };

  # ── Change this to switch your entire system theme ──
  active = "everforest-dark-hard";
in
  schemes.${active}
