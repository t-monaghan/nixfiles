{pkgs, lib, ...}:
let
  fonts = import ./fonts.nix;
in {
  enable = true;
  package = null;
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
      dark = "One Dark";
      light = "One Light";
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
