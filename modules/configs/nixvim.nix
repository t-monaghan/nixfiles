{pkgs, ...}: {
  enable = true;
  defaultEditor = true;
  imports = [
    ./neovim-plugins.nix
    ./neovim-lsp.nix
  ];

  globals = {
    mapleader = " ";
    maplocalleader = " ";
    have_nerd_font = true;
  };

  opts = {
    number = true;
    mouse = "a";
    showmode = false;
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
    timeoutlen = 300;
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
  };

  autoCmd = [
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
      event = ["UIEnter"];
      desc = "Ensure colorscheme is applied";
      callback.__raw = ''
        function()
          vim.cmd.colorscheme("base16-everforest-dark-hard")
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
        end
      '';
    }
  ];

  diagnostics = {
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

  colorscheme = "base16-everforest-dark-hard";
  extraPlugins = with pkgs.vimPlugins; [
    base16-nvim
    monokai-pro-nvim
  ];

  extraConfigLua = ''
    vim.schedule(function()
      vim.opt.clipboard = "unnamedplus"
    end)
  '';
}
