{pkgs, lib, ...}:
let
  fonts = import ./fonts.nix;
in {
  enable = true;
  package = null;
  userSettings = {
    edit_predictions = true;
    agent = {
      inline_alternatives = [
        {
          provider = "copilot_chat";
          model = "claude-3.5-sonnet";
        }
      ];
    };
    lsp = {
      yaml-language-server = {
        settings = {
          yaml = {
            keyOrdering = false;
          };
        };
      };
      golangci-lint-langserver = {
        initialization_options = {
          command = [
            "golangci-lint"
            "run"
            "--out-format"
            "json"
            "--issues-exit-code=1"
          ];
        };
      };
    };
    auto_update = false;
    features = {
      inline_completion_provider = "copilot";
    };
    project_panel = {
      button = true;
      default_width = 300;
      dock = "left";
      file_icons = true;
      folder_icons = true;
      git_status = true;
      indent_size = 20;
      auto_reveal_entries = true;
    };
    tabs = {
      git_status = true;
    };
    theme = {
      mode = "system";
      light = "Monokai Pro Light";
      dark = "Everforest Dark";
    };
    buffer_font_family = fonts.monoNerdFont;
    buffer_font_size = fonts.size;
    ui_font_size = fonts.size;
    ui_font_family = fonts.monoNerdFont;
    show_whitespaces = "selection";
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    vim_mode = true;
    relative_line_numbers = true;
    scrollbar = {
      show = "never";
    };
    vertical_scroll_margin = 8;
    gutter = {
      line_numbers = true;
      code_actions = true;
      folds = true;
    };
    git = {
      inline_blame = {
        enabled = false;
      };
    };
    terminal = {
      shell = {
        program = "${lib.getExe pkgs.fish}";
      };
      dock = "bottom";
      default_height = 400;
      font_family = fonts.monoNerdFont;
      font_size = fonts.size;
      line_height = "comfortable";
    };
    languages = {
      Go = {
        tab_size = 4;
        hard_tabs = true;
        language_servers = ["gopls" "golangci-lint-langserver" "..."];
      };
      Python = {
        language_servers = ["pyright" "ruff" "..."];
        formatter = {
          external = {
            command = "ruff";
            arguments = ["format" "-"];
          };
        };
      };
      TypeScript = {
        code_actions_on_format = {
          "source.organizeImports" = true;
        };
      };
      TSX = {
        code_actions_on_format = {
          "source.organizeImports" = true;
        };
      };
      Markdown = {
        soft_wrap = "preferred_line_length";
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
