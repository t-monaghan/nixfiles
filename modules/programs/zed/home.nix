{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.zed.enable {
  programs.zed-editor = {
    enable = true;
    package = null; # installed outside Nix on macOS

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
      ui_font_size = 15;
      buffer_font_size = 16;
      ui_font_family = "JetBrainsMonoNL Nerd Font Mono";
      buffer_font_family = "JetBrainsMonoNL Nerd Font Mono";
      buffer_font_weight = 500;
      terminal = {
        env.EDITOR = "nvim";
        font_size = 16;
        copy_on_select = true;
        font_family = "JetBrainsMono Nerd Font Mono";
        line_height = "standard";
      };
      git.inline_blame.show_commit_summary = true;
      notification_panel.button = false;
      collaboration_panel.button = false;
      debugger.button = false;
      autosave = "on_focus_change";
      languages = {
        Go = {
          language_servers = ["gopls" "golangci-lint-langserver" "..."];
        };
        Python = {
          language_servers = ["ty" "!basedpyright"];
          format_on_save = "on";
          formatter = [
            {code_action = "source.fixAll.ruff";}
            {language_server.name = "ruff";}
          ];
          show_edit_predictions = false;
        };
        TypeScript.format_on_save = "off";
        "Plain Text".show_edit_predictions = false;
        Markdown.soft_wrap = "editor_width";
      };
    };

    userKeymaps = [
      {
        bindings = {
          "cmd-shift-d" = "diagnostics::Deploy";
          "cmd-o" = "projects::OpenRecent";
        };
      }
      {
        context = "vim_mode == insert";
        bindings = {
          "j k" = "vim::NormalBefore";
        };
      }
      {
        context = "EmptyPane || SharedScreen";
        bindings = {
          "space f" = "file_finder::Toggle";
          "G s" = "project_symbols::Toggle";
        };
      }
      {
        context = "vim_mode == visual";
        bindings = {
          "shift-s" = ["vim::PushOperator" {AddSurrounds = {};}];
        };
      }
    ];

    userTasks = [
      {
        label = "Devbox Test";
        command = "devbox run test";
        use_new_terminal = true;
        allow_concurrent_runs = false;
        reveal = "always";
      }
      {
        label = "Devbox Services Up";
        command = "devbox services up";
        use_new_terminal = true;
        allow_concurrent_runs = false;
        reveal = "always";
      }
      {
        label = "Watch GitHub Run";
        command = "gh run watch";
        use_new_terminal = true;
        allow_concurrent_runs = true;
        reveal = "always";
      }
    ];
  };
}
