{
  pkgs,
  lib,
  colors,
  ...
}: let
  fonts = import ./fonts.nix;

  # A Zed theme built from one of our palettes, so Zed shows the same colours as
  # Ghostty and Neovim. Zed has no base16 support and no way to accept a bare
  # palette, so the slots are mapped onto its style keys here, using the roles
  # the base16 specification assigns them (see ./colours.nix). Style keys we do
  # not set fall back to Zed's own defaults.
  mkTheme = name: appearance: p: let
    ansi = colors.terminalPalette p;
    at = i: lib.elemAt ansi i;
  in {
    inherit name appearance;
    style =
      {
        background = p.base00;
        "border" = p.base02;
        "border.variant" = p.base01;
        "border.focused" = p.base0D;
        "border.selected" = p.base0D;
        "elevated_surface.background" = p.base01;
        "surface.background" = p.base01;
        "element.background" = p.base01;
        "element.hover" = p.base02;
        "element.selected" = p.base02;
        "drop_target.background" = p.base03;
        "ghost_element.hover" = p.base01;
        "ghost_element.selected" = p.base02;

        text = p.base05;
        "text.muted" = p.base04;
        "text.placeholder" = p.base03;
        "text.disabled" = p.base03;
        "text.accent" = p.base0D;
        icon = p.base05;
        "icon.muted" = p.base04;
        "icon.accent" = p.base0D;

        "status_bar.background" = p.base01;
        "title_bar.background" = p.base01;
        "toolbar.background" = p.base00;
        "tab_bar.background" = p.base01;
        "tab.inactive_background" = p.base01;
        "tab.active_background" = p.base00;
        "panel.background" = p.base01;
        "panel.focused_border" = p.base0D;
        "search.match_background" = p.base0A;

        "scrollbar.thumb.background" = p.base02;
        "scrollbar.thumb.hover_background" = p.base03;
        "scrollbar.thumb.border" = p.base02;
        "scrollbar.track.background" = p.base00;
        "scrollbar.track.border" = p.base01;

        "editor.foreground" = p.base05;
        "editor.background" = p.base00;
        "editor.gutter.background" = p.base00;
        "editor.active_line.background" = p.base01;
        "editor.highlighted_line.background" = p.base01;
        "editor.line_number" = p.base03;
        "editor.active_line_number" = p.base05;
        "editor.invisible" = p.base03;
        "editor.wrap_guide" = p.base01;
        "editor.active_wrap_guide" = p.base02;
        "editor.document_highlight.read_background" = p.base02;
        "editor.document_highlight.write_background" = p.base02;

        "terminal.background" = p.base00;
        "terminal.foreground" = p.base05;
        "terminal.dim_foreground" = p.base04;
        "terminal.bright_foreground" = p.base07;

        created = p.base0B;
        modified = p.base0A;
        deleted = p.base08;
        conflict = p.base09;
        error = p.base08;
        warning = p.base0A;
        info = p.base0D;
        success = p.base0B;
        hint = p.base0C;
        predictive = p.base03;
        ignored = p.base03;
        hidden = p.base03;

        players = [
          {
            cursor = p.base0D;
            background = p.base0D;
            selection = p.base02;
          }
        ];

        # base16's syntax roles: 08 variables, 09 constants, 0A types,
        # 0B strings, 0C escapes, 0D functions, 0E keywords, 0F embedded.
        syntax = lib.mapAttrs (_: color: {inherit color;}) {
          comment = p.base03;
          "comment.doc" = p.base03;
          variable = p.base05;
          "variable.special" = p.base08;
          tag = p.base08;
          constant = p.base09;
          number = p.base09;
          boolean = p.base09;
          attribute = p.base09;
          type = p.base0A;
          constructor = p.base0A;
          string = p.base0B;
          "string.escape" = p.base0C;
          "string.regex" = p.base0C;
          "string.special" = p.base0C;
          function = p.base0D;
          "function.method" = p.base0D;
          title = p.base0D;
          link_uri = p.base0D;
          link_text = p.base0C;
          property = p.base0D;
          keyword = p.base0E;
          operator = p.base0E;
          embedded = p.base0F;
          punctuation = p.base05;
          "punctuation.bracket" = p.base05;
          "punctuation.delimiter" = p.base05;
          label = p.base0A;
          enum = p.base0A;
          variant = p.base09;
          primary = p.base05;
          predictive = p.base03;
          hint = p.base0C;
        };
      }
      # Zed's terminal shows the same ANSI slots as Ghostty, taken from the same
      # list so the two cannot drift.
      // {
        "terminal.ansi.black" = at 0;
        "terminal.ansi.red" = at 1;
        "terminal.ansi.green" = at 2;
        "terminal.ansi.yellow" = at 3;
        "terminal.ansi.blue" = at 4;
        "terminal.ansi.magenta" = at 5;
        "terminal.ansi.cyan" = at 6;
        "terminal.ansi.white" = at 7;
        "terminal.ansi.bright_black" = at 8;
        "terminal.ansi.bright_red" = at 9;
        "terminal.ansi.bright_green" = at 10;
        "terminal.ansi.bright_yellow" = at 11;
        "terminal.ansi.bright_blue" = at 12;
        "terminal.ansi.bright_magenta" = at 13;
        "terminal.ansi.bright_cyan" = at 14;
        "terminal.ansi.bright_white" = at 15;
      };
  };
in {
  enable = true;
  package = null;

  themes.nixfiles = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "Nixfiles";
    author = "nixfiles";
    themes = [
      (mkTheme "Nixfiles Dark" "dark" colors.palettes.dark)
      (mkTheme "Nixfiles Light" "light" colors.palettes.light)
    ];
  };
  userSettings = {
    show_edit_predictions = false;
    edit_predictions = {
      provider = "copilot";
      mode = "subtle";
      enabled_in_text_threads = false;
    };
    agent = {
      default_model = {
        provider = "copilot_chat";
        model = "claude-3.7-sonnet-thought";
      };
      inline_assistant_model = {
        provider = "copilot_chat";
        model = "gpt-4.1";
      };
      inline_alternatives = [
        {
          provider = "copilot_chat";
          model = "gpt-4o";
        }
      ];
    };
    lsp = {
      yaml-language-server = {
        settings = {
          yaml = {
            format.singleQuote = true;
            schemas = {
              "https://raw.githubusercontent.com/cultureamp/devbox-extras/main/process-compose/schema.yaml" = "/process-compose.yaml";
            };
          };
        };
      };
      golangci-lint-langserver = {
        initialization_options = {
          command = [
            "golangci-lint"
            "run"
            "--output.json.path"
            "stdout"
            "--show-stats=false"
            "--issues-exit-code=1"
          ];
        };
      };
    };
    project_panel.indent_size = 10;
    outline_panel.dock = "right";
    auto_update_extensions.toml = false;
    tabs = {
      git_status = true;
      file_icons = true;
      show_diagnostics = "all";
    };
    theme = {
      mode = "system";
      dark = "Nixfiles Dark";
      light = "Nixfiles Light";
    };
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    soft_wrap = "none";
    cursor_blink = false;
    vim_mode = true;
    vim.use_system_clipboard = "always";
    scroll_beyond_last_line = "off";
    ui_font_size = fonts.size;
    buffer_font_size = fonts.size;
    ui_font_family = fonts.monoNerdFont;
    buffer_font_family = fonts.monoNerdFont;
    buffer_font_weight = 500;
    git.inline_blame.show_commit_summary = true;
    notification_panel.button = false;
    collaboration_panel.button = false;
    debugger.button = false;
    autosave = "on_focus_change";
    terminal = {
      env.EDITOR = "nvim";
      font_size = fonts.size;
      copy_on_select = true;
      font_family = fonts.monoNerdFont;
      line_height = "standard";
    };
    languages = {
      Go = {
        language_servers = ["gopls" "golangci-lint-langserver" "..."];
      };
    };
  };
  userKeymaps = [
    {
      context = "Editor && vim_mode == insert && !menu";
      bindings = {
        j = {
          k = "vim::NormalBefore";
        };
      };
    }
  ];
  userTasks = [
    {
      label = "Devbox Test";
      command = "devbox run test";
      use_new_terminal = false;
    }
    {
      label = "Devbox Services Up";
      command = "devbox services up";
      use_new_terminal = false;
    }
    {
      label = "Watch GitHub Run";
      command = "gh run watch";
      use_new_terminal = false;
    }
  ];
}
