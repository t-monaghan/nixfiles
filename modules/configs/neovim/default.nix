# Shared nixvim configuration — used by ALL three machines.
#
# Imported as a module by both the Mac home-manager configs (../../home.nix) and
# the NixOS box (../../../nixos/neovim.nix); `programs.nixvim` is declared by
# nixvim's home-manager and NixOS modules alike, so one file serves both. The
# arguments below come from `_module.args` / `extraSpecialArgs` (see
# ../../args.nix and ../../../lib/mkHost.nix). Host differences are limited to:
#
# - `flakePath` + `homeConfigName`: on the Macs they point nixd at this flake;
#   on the NixOS box both are null (set in ../../../nixos/neovim.nix) and nixd
#   falls back to the channel-based `<nixpkgs>` expressions — see ./lsp.nix.
# - `pkgs.stdenv.isDarwin`: gates the macOS `defaults read` light/dark probe and
#   the Obsidian plugin.
#
# Colours come from the two palettes in ../colours.nix, handed to base16-nvim as
# hex slots. No colorscheme is named here: `colorschemes.base16.colorscheme`
# takes the slots directly, and auto-dark-mode swaps palettes at runtime by
# calling `setup` again.
{
  pkgs,
  lib,
  colors,
  flakePath,
  homeConfigName,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;

  inherit (colors) palettes;
  # base16-nvim's `setup` takes the 16 slots as a Lua table. The palettes hold
  # nothing else, so every attribute is emitted.
  toLuaTable = p: "{ ${lib.concatStringsSep " " (lib.mapAttrsToList (slot: hex: ''${slot} = "${hex}",'') p)} }";
in {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    imports = [
      ./plugins.nix
      ./lsp.nix
      ./obsidian.nix
    ];

    # Make the host parameters available to nixvim submodules
    # (lsp.nix wires flakePath/homeConfigName into nixd's settings;
    # obsidian.nix gates on isDarwin).
    _module.args = {inherit flakePath homeConfigName isDarwin;};

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };

    opts = {
      # Force truecolor: base16-nvim uses gui highlights, and Neovim only
      # auto-enables this when $COLORTERM=truecolor is set — which SSH doesn't
      # forward. Without it, colours don't render over SSH (white-on-black).
      termguicolors = true;
      number = true;
      mouse = "a";
      showmode = false;
      showcmd = false;
      ruler = false;
      cmdheight = 0;
      clipboard = {
        providers = {
          wl-copy.enable = true;
          wl-paste.enable = true;
          xclip.enable = true;
          xsel.enable = true;
        };
        register = "unnamedplus";
      };
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 500;
      splitright = true;
      splitbelow = true;
      list = true;
      listchars = {
        tab = "» ";
        trail = "·";
        nbsp = "␣";
      };
      inccommand = "split";
      cursorline = true;
      scrolloff = 10;
      hlsearch = true;
      wrap = false;
      linebreak = false;
      path = ".,**";
    };

    keymaps = [
      {
        mode = "i";
        key = "jk";
        action = "<Esc>";
        options.desc = "Exit insert mode";
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
      }
      {
        mode = "n";
        key = "<leader>q";
        action.__raw = "vim.diagnostic.setloclist";
        options.desc = "Open diagnostic [Q]uickfix list";
      }
      {
        mode = "t";
        key = "<Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
      }
      {
        mode = "t";
        key = "<A-Esc>";
        action = "<Esc>";
        options.desc = "Send ESC to terminal";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w><C-h>";
        options.desc = "Move focus to the left window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w><C-l>";
        options.desc = "Move focus to the right window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w><C-j>";
        options.desc = "Move focus to the lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w><C-k>";
        options.desc = "Move focus to the upper window";
      }
      {
        mode = "n";
        key = "<leader>yp";
        action.__raw = ''
          function()
            local path = vim.fn.expand("%:p")
            vim.fn.setreg("+", path)
            vim.notify("Copied: " .. path, vim.log.levels.INFO)
          end
        '';
        options.desc = "[Y]ank file [P]ath (absolute)";
      }
    ];

    autoGroups = {
      kickstart-highlight-yank = {clear = true;};
      markdown-wrap = {clear = true;};
      terminal-config = {clear = true;};
    };

    autoCmd =
      [
        {
          event = ["TermEnter"];
          group = "terminal-config";
          command = "setlocal winhighlight=Normal:ActiveTerm";
        }
        {
          event = ["TermLeave"];
          group = "terminal-config";
          command = "setlocal winhighlight=Normal:NC";
        }
        {
          event = ["TermOpen"];
          group = "terminal-config";
          callback.__raw = ''
            function()
              vim.cmd([[ setlocal nonumber norelativenumber signcolumn=no ]])
              vim.opt.scrolloff = 0
              vim.opt.sidescrolloff = 0
              vim.opt.guicursor:append("t:block-blinkon0")
              vim.keymap.set("n", "<C-c>", [[ i<C-c><C-\><C-n> ]], { buffer = 0 })
              vim.keymap.set("n", "<C-n>", [[ i<C-n><C-\><C-n> ]], { buffer = 0 })
              vim.keymap.set("n", "<C-p>", [[ i<C-p><C-\><C-n> ]], { buffer = 0 })
              vim.keymap.set("n", "<CR>", [[ i<CR><C-\><C-n> ]], { buffer = 0 })
              vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Exit terminal mode"  })
              vim.cmd("startinsert")
            end
          '';
        }
        {
          event = ["TermRequest"];
          group = "terminal-config";
          desc = "Pass through OSC 777 notifications to parent terminal";
          callback.__raw = ''
            function(ev)
              local seq = ev.data and ev.data.sequence
              if seq and seq:match("^\027]777;") then
                io.stdout:write(seq)
              end
            end
          '';
        }
        {
          event = ["TextYankPost"];
          desc = "Highlight when yanking (copying) text";
          group = "kickstart-highlight-yank";
          callback.__raw = ''
            function()
              vim.highlight.on_yank()
            end
          '';
        }
        {
          event = ["FileType"];
          pattern = ["markdown"];
          desc = "Enable soft wrapping for markdown files";
          group = "markdown-wrap";
          callback.__raw = ''
            function()
              vim.opt_local.wrap = true
              vim.opt_local.linebreak = true
              vim.opt_local.conceallevel = 2
            end
          '';
        }
      ]
      # macOS only: probe the system appearance once the UI attaches, since
      # auto-dark-mode's first poll can lag the initial colorscheme.
      ++ lib.optional isDarwin {
        event = ["UIEnter"];
        desc = "Ensure colorscheme is applied";
        callback.__raw = ''
          function()
            local mode = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
            _G.nixfiles_set_appearance(mode == "Dark" and "dark" or "light")
          end
        '';
      };

    diagnostic.settings = {
      underline = true;
      update_in_insert = false;
      virtual_text = {
        spacing = 4;
        source = "if_many";
        prefix = "●";
      };
      severity_sort = true;
      signs = {
        text = {
          __raw = ''
            {
              [vim.diagnostic.severity.ERROR] = " ",
              [vim.diagnostic.severity.WARN] = " ",
              [vim.diagnostic.severity.HINT] = " ",
              [vim.diagnostic.severity.INFO] = " ",
            }
          '';
        };
      };
    };

    # Dark is the startup palette; auto-dark-mode switches to light below if the
    # system is in light mode.
    colorschemes.base16 = {
      enable = true;
      colorscheme = palettes.dark;
    };

    # Formatters that conform runs (must be on nvim's PATH). Without these,
    # conform's `lsp_format = "fallback"` hands formatting to nixd, which has no
    # formatter configured -> the RPC error on :w.
    extraPackages = with pkgs; [
      alejandra # nix (default)
      hujsonfmt # hujson
      nixpkgs-fmt # nix (inside nixpkgs trees)
      stylua # lua
      ruff # python
      prettierd # typescript
    ];
    # base16-nvim itself comes from `colorschemes.base16` above.

    extraConfigLua = ''
      vim.filetype.add({
        extension = {
          hujson = "jsonc",
        },
      })

      vim.schedule(function()
        vim.opt.clipboard = "unnamedplus"
      end)

      -- Make backgrounds transparent so the terminal shows through
      local function make_transparent()
        local groups = {
          "Normal", "NormalNC",
          "SignColumn", "EndOfBuffer",
          "MsgArea", "MiniStatuslineFilename",
          "TreesitterContext",
          -- Gutter: line numbers & git signs
          "LineNr", "CursorLineNr", "CursorLine", "FoldColumn",
          "GitSignsAdd", "GitSignsChange", "GitSignsDelete",
          "GitSignsTopdelete", "GitSignsChangedelete", "GitSignsUntracked",
          "DiagnosticSignError", "DiagnosticSignWarn", "DiagnosticSignInfo", "DiagnosticSignHint",
        }
        for _, group in ipairs(groups) do
          vim.api.nvim_set_hl(0, group, { bg = "NONE" })
        end
      end

      local base16 = require("base16-colorscheme")

      local palettes = {
        dark = ${toLuaTable palettes.dark},
        light = ${toLuaTable palettes.light},
      }

      -- Floating windows sit one step off the background: base01 of the palette
      -- in use.
      local float_bg = {
        dark = "${palettes.dark.base01}",
        light = "${palettes.light.base01}",
      }

      -- The one place that changes palette. base16-nvim's `setup` assigns
      -- highlights directly instead of running `:colorscheme`, so it fires no
      -- ColorScheme event and every call resets Normal's background to base00 --
      -- which undoes the transparency. Re-apply the overrides here, after each
      -- `setup`, or the background turns opaque on the first appearance poll.
      function _G.nixfiles_set_appearance(mode)
        vim.o.background = mode
        base16.setup(palettes[mode])
        make_transparent()
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = float_bg[mode] })
      end

      -- A manual `:colorscheme` does fire the event, so keep honouring it.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("transparent-bg", { clear = true }),
        callback = function()
          make_transparent()
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = float_bg[vim.o.background] })
        end,
      })

      require("auto-dark-mode").setup({
        set_dark_mode = function()
          _G.nixfiles_set_appearance("dark")
        end,
        set_light_mode = function()
          _G.nixfiles_set_appearance("light")
        end,
      })

      -- Apply now: nixvim ran its own `base16.setup` before this file, so the
      -- overrides are not yet in place.
      _G.nixfiles_set_appearance(vim.o.background)
    '';
  };
}
