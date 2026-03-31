{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.programs.neovim.enable {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    imports = [
      ./plugins.nix
      ./lsp.nix
    ];

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
    };

    opts = {
      wrap = false;
      number = true;
      mouse = "a";
      showmode = false;
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      list = true;
      listchars = {
        tab = "  ";
        trail = "·";
        nbsp = "␣";
      };
      inccommand = "split";
      cursorline = true;
      scrolloff = 5;
      tabstop = 4;
      confirm = true;
    };

    keymaps = [
      {
        mode = ["i" "v"];
        key = "jk";
        action = "<Esc>";
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
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
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
    ];

    autoGroups.kickstart-highlight-yank.clear = true;

    autoCmd = [
      {
        event = "TextYankPost";
        desc = "Highlight when yanking (copying) text";
        group = "kickstart-highlight-yank";
        callback.__raw = "function() vim.hl.on_yank() end";
      }
      # Terminal-driven dark mode (Ghostty sends background changes via OSC)
      {
        event = "OptionSet";
        pattern = "background";
        callback.__raw = ''
          function()
            if vim.o.background == "dark" then
              vim.cmd("colorscheme base16-everforest-dark-hard")
            else
              vim.cmd("colorscheme monokai-pro-light")
            end
          end
        '';
      }
    ];

    diagnostics = {
      severity_sort = true;
      float = {
        border = "rounded";
        source = "if_many";
      };
      underline = {
        severity.__raw = "vim.diagnostic.severity.ERROR";
      };
      signs = {
        text.__raw = ''
          {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          }
        '';
      };
      virtual_text = {
        source = "if_many";
        spacing = 2;
        format.__raw = ''
          function(diagnostic)
            return diagnostic.message
          end
        '';
      };
    };

    # Default colorscheme (dark)
    colorscheme = "base16-everforest-dark-hard";
    extraPlugins = with pkgs.vimPlugins; [
      base16-nvim
      monokai-pro-nvim
    ];

    # Clipboard scheduled after UiEnter for faster startup
    extraConfigLua = ''
      vim.schedule(function()
        vim.o.clipboard = "unnamedplus"
      end)
    '';
  };
}
