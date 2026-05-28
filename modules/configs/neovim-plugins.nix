{pkgs, ...}: {
  plugins = {
    sleuth.enable = true;

    indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = "▏";
          tab_char = "▏";
        };
        scope.show_start = false;
      };
    };

    flash = {
      enable = true;
      settings = {
        modes.search.enabled = true;
      };
    };

    gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_opts.delay = 0;
        signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
        on_attach.__raw = ''
          function(bufnr)
            local gitsigns = require("gitsigns")
            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end
            -- Navigation
            map("n", "]c", function()
              if vim.wo.diff then vim.cmd.normal({"]c", bang = true})
              else gitsigns.nav_hunk("next") end
            end, {desc = "Jump to next git [c]hange"})
            map("n", "[c", function()
              if vim.wo.diff then vim.cmd.normal({"[c", bang = true})
              else gitsigns.nav_hunk("prev") end
            end, {desc = "Jump to previous git [c]hange"})
            -- Actions (visual mode)
            map("v", "<leader>hs", function() gitsigns.stage_hunk({vim.fn.line("."), vim.fn.line("v")}) end, {desc = "git [s]tage hunk"})
            map("v", "<leader>hr", function() gitsigns.reset_hunk({vim.fn.line("."), vim.fn.line("v")}) end, {desc = "git [r]eset hunk"})
            -- Actions (normal mode)
            map("n", "<leader>hs", gitsigns.stage_hunk, {desc = "git [s]tage hunk"})
            map("n", "<leader>hr", gitsigns.reset_hunk, {desc = "git [r]eset hunk"})
            map("n", "<leader>hS", gitsigns.stage_buffer, {desc = "git [S]tage buffer"})
            map("n", "<leader>hu", gitsigns.undo_stage_hunk, {desc = "git [u]ndo stage hunk"})
            map("n", "<leader>hR", gitsigns.reset_buffer, {desc = "git [R]eset buffer"})
            map("n", "<leader>hp", gitsigns.preview_hunk, {desc = "git [p]review hunk"})
            map("n", "<leader>hb", gitsigns.blame_line, {desc = "git [b]lame line"})
            map("n", "<leader>hd", gitsigns.diffthis, {desc = "git [d]iff against index"})
            map("n", "<leader>hD", function() gitsigns.diffthis("@") end, {desc = "git [D]iff against last commit"})
            -- Toggles
            map("n", "<leader>tb", gitsigns.toggle_current_line_blame, {desc = "[T]oggle git show [b]lame line"})
            map("n", "<leader>tD", gitsigns.preview_hunk_inline, {desc = "[T]oggle git show [D]eleted"})
          end
        '';
      };
    };

    which-key = {
      enable = true;
      settings = {
        delay = 0;
        icons = {
          mappings = true;
          keys = {};
        };
        spec = [
          {
            __unkeyed-1 = "<leader>s";
            group = "[S]earch";
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "[T]oggle";
          }
          {
            __unkeyed-1 = "<leader>h";
            group = "Git [H]unk";
            mode = ["n" "v"];
          }
          {
            __unkeyed-1 = "<leader>o";
            group = "[O]bsidian";
          }
        ];
      };
    };

    telescope = {
      enable = true;
      settings.pickers.find_files.find_command = ["rg" "--files" "--hidden" "-g" "!.git"];
      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
      keymaps = {
        "<leader>sh" = {
          action = "help_tags";
          options.desc = "[S]earch [H]elp";
        };
        "<leader>sk" = {
          action = "keymaps";
          options.desc = "[S]earch [K]eymaps";
        };
        "<leader>sf" = {
          action = "find_files";
          options.desc = "[S]earch [F]iles";
        };
        "<leader>ss" = {
          action = "builtin";
          options.desc = "[S]earch [S]elect Telescope";
        };
        "<leader>sw" = {
          action = "grep_string";
          options.desc = "[S]earch current [W]ord";
        };
        "<leader>sg" = {
          action = "live_grep";
          options.desc = "[S]earch by [G]rep";
        };
        "<leader>sd" = {
          action = "diagnostics";
          options.desc = "[S]earch [D]iagnostics";
        };
        "<leader>sr" = {
          action = "resume";
          options.desc = "[S]earch [R]esume";
        };
        "<leader>s." = {
          action = "oldfiles";
          options.desc = "[S]earch Recent Files";
        };
        "<leader><leader>" = {
          action = "buffers";
          options.desc = "[ ] Find existing buffers";
        };
        "<leader>gs" = {
          action = "git_status";
          options.desc = "[G]it [S]tatus files";
        };
      };
    };

    lazydev = {
      enable = true;
      settings.library = [
        {
          path = "\${3rd}/luv/library";
          words = ["vim%.uv"];
        }
      ];
    };

    fidget = {
      enable = true;
      settings.notification.window = {
        normal_hl = "NormalFloat";
        winblend = 0;
      };
    };

    conform-nvim = {
      enable = true;
      settings = {
        notify_on_error = false;
        format_on_save.__raw = ''
          function(bufnr)
            local disable_filetypes = {c = true, cpp = true}
            if disable_filetypes[vim.bo[bufnr].filetype] then
              return nil
            else
              return {timeout_ms = 500, lsp_format = "fallback"}
            end
          end
        '';
        formatters_by_ft = {
          lua = ["stylua"];
          nix = {
            __raw = ''
              function(bufnr)
                local path = vim.api.nvim_buf_get_name(bufnr)
                if path:match("/nixpkgs/") or path:match("/nixpkgs%-") then
                  return {"nixpkgs_fmt"}
                else
                  return {"alejandra"}
                end
              end
            '';
          };
          python = ["ruff"];
          typescript = ["prettierd"];
        };
      };
    };

    blink-cmp = {
      enable = true;
      settings = {
        keymap = {
          preset = "default";
          "<CR>" = ["accept" "fallback"];
          "<C-y>" = [];
        };
        appearance.nerd_font_variant = "mono";
        completion.documentation = {
          auto_show = false;
          auto_show_delay_ms = 500;
        };
        sources = {
          default = ["lsp" "path" "snippets" "lazydev"];
          providers.lazydev = {
            module = "lazydev.integrations.blink";
            score_offset = 100;
          };
        };
        snippets.preset = "luasnip";
        fuzzy.implementation = "lua";
        signature.enabled = true;
      };
    };

    luasnip.enable = true;

    todo-comments = {
      enable = true;
      settings.signs = false;
    };

    mini = {
      enable = true;
      modules = {
        ai = {n_lines = 500;};
        surround = {
          mappings = {
            add = "Sa";
            delete = "Sd";
            find = "";
            find_left = "";
            highlight = "";
            replace = "Sr";
            update_n_lines = "";
          };
        };
        statusline = {};
      };
    };

    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
    };

    treesitter-context.enable = true;

    nvim-autopairs.enable = true;

    web-devicons.enable = true;
  };

  extraPlugins = with pkgs.vimPlugins; [
    (pkgs.vimUtils.buildVimPlugin {
      name = "gh-permalink.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "vieitesss";
        repo = "gh-permalink.nvim";
        rev = "9e337278ab5218d17b86f611c77be5fb5e6a263d";
        hash = "sha256-gDoB1Ynia+Fychsc8L9sjD6eR9t76kCb0JsiZFh9dRA=";
      };
    })
    (pkgs.vimUtils.buildVimPlugin {
      name = "auto-dark-mode.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "f-person";
        repo = "auto-dark-mode.nvim";
        rev = "54058b4fe414bd64bd2904a6f8a63f1f14e3d8df";
        hash = "sha256-xTgRyct3L6Gcz/vdYSc+h2IUgi/+Lh1Q4mxJwHISeis=";
      };
    })
  ];

  # Extra telescope keymaps that need raw Lua (custom picker functions)
  keymaps = [
    # {
    #   mode = ["n" "x" "o"];
    #   key = "S";
    #   action.__raw = ''function() require("flash").jump() end'';
    #   options.desc = "Flash";
    # }
    {
      mode = ["x" "o"];
      key = "s";
      action.__raw = ''function() require("flash").treesitter() end'';
      options.desc = "Flash Treesitter";
    }
    {
      mode = "o";
      key = "r";
      action.__raw = ''function() require("flash").remote() end'';
      options.desc = "Remote Flash";
    }
    {
      mode = ["o" "x"];
      key = "R";
      action.__raw = ''function() require("flash").treesitter_search() end'';
      options.desc = "Treesitter Search";
    }
    {
      mode = "c";
      key = "<c-s>";
      action.__raw = ''function() require("flash").toggle() end'';
      options.desc = "Toggle Flash Search";
    }
    {
      mode = "n";
      key = "<leader>/";
      action.__raw = ''
        function()
          require("telescope.builtin").current_buffer_fuzzy_find(
            require("telescope.themes").get_dropdown({winblend = 10, previewer = false})
          )
        end
      '';
      options.desc = "[/] Fuzzily search in current buffer";
    }
    {
      mode = "n";
      key = "<leader>s/";
      action.__raw = ''
        function()
          require("telescope.builtin").live_grep({grep_open_files = true, prompt_title = "Live Grep in Open Files"})
        end
      '';
      options.desc = "[S]earch [/] in Open Files";
    }
    {
      mode = "n";
      key = "<leader>sn";
      action.__raw = ''
        function()
          require("telescope.builtin").find_files({cwd = vim.fn.stdpath("config")})
        end
      '';
      options.desc = "[S]earch [N]eovim files";
    }
    {
      mode = "";
      key = "<leader>f";
      action.__raw = ''
        function()
          require("conform").format({async = true, lsp_format = "fallback"})
        end
      '';
      options.desc = "[F]ormat buffer";
    }
    {
      mode = "i";
      key = "<C-f>";
      action.__raw = ''
        function()
          require("telescope.builtin").find_files()
        end
      '';
      options.desc = "Find files (insert mode)";
    }
    {
      mode = ["n" "v"];
      key = "<leader>yg";
      action.__raw = ''
        function()
          require("gh-permalink").yank()
        end
      '';
      options.desc = "Copy GitHub permalink";
    }
  ];

  # mini.statusline overrides
  extraConfigLua = ''
    local statusline = require("mini.statusline")
    statusline.section_location = function()
      return "%2l:%-2v"
    end

    -- Show terminal title (running command) instead of shell name
    statusline.section_filename = function(args)
      if vim.bo.buftype == "terminal" then
        return vim.b.term_title or "%t"
      elseif statusline.is_truncated(args.trunc_width) then
        return "%f%m%r"
      else
        return "%F%m%r"
      end
    end

    -- Hide fileinfo (encoding, filesize, filetype) from statusline
    statusline.section_fileinfo = function()
      return ""
    end

    -- Hide LSP attached indicator
    statusline.section_lsp = function()
      return ""
    end

    -- Use custom icon for diagnostics
    local orig_diagnostics = statusline.section_diagnostics
    statusline.section_diagnostics = function(args)
      args = args or {}
      args.icon = "\xEF\x80\x82"
      return orig_diagnostics(args)
    end
  '';
}
