{
  pkgs,
  colors,
  ...
}: {
  enable = true;
  defaultEditor = true;
  imports = [
    ./neovim-plugins.nix
    ./neovim-lsp.nix
    ./neovim-obsidian.nix
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

  autoCmd = [
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
      event = ["UIEnter"];
      desc = "Ensure colorscheme is applied";
      callback.__raw = ''
        function()
          local mode = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
          if mode == "Dark" then
            vim.o.background = "dark"
            vim.cmd.colorscheme("${colors.nixvim.dark}")
          else
            vim.o.background = "light"
            vim.cmd.colorscheme("${colors.nixvim.light}")
          end
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

  colorscheme = colors.nixvim.dark;
  extraPlugins = with pkgs.vimPlugins; [
    base16-nvim
    monokai-pro-nvim
  ];

  extraConfigLua = ''
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

    -- Boost contrast for the light colorscheme — Monokai Pro Light's defaults
    -- are near-invisible on its #faf4f0 cream background.
    local function boost_light_contrast()
      if vim.o.background ~= "light" then return end
      -- Selection: warm dark tone (~2× RGB delta from bg)
      vim.api.nvim_set_hl(0, "Visual",       { bg = "#96865c" })
      vim.api.nvim_set_hl(0, "VisualNOS",    { bg = "#96865c" })
      vim.api.nvim_set_hl(0, "Search",       { bg = "#f0d78c", fg = "#272822" })
      vim.api.nvim_set_hl(0, "IncSearch",    { bg = "#f0a878", fg = "#272822" })
      vim.api.nvim_set_hl(0, "CurSearch",    { bg = "#f0a878", fg = "#272822" })
      -- Cursor: make_transparent() strips CursorLine/CursorLineNr bg; restore them
      vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#e5d8c8" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#272822", bold = true })
      vim.api.nvim_set_hl(0, "Cursor",       { bg = "#272822", fg = "#faf4f0" })
      -- Comments: dark warm brown instead of the near-invisible default grey
      vim.api.nvim_set_hl(0, "Comment",      { fg = "#6b5e48" })
      vim.api.nvim_set_hl(0, "@comment",     { fg = "#6b5e48" })
    end

    -- Apply transparency after every colorscheme change
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("transparent-bg", { clear = true }),
      callback = function()
        make_transparent()
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "${colors.bg1}" })
        boost_light_contrast()
      end,
    })

    require("auto-dark-mode").setup({
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd.colorscheme("${colors.nixvim.dark}")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd.colorscheme("${colors.nixvim.light}")
      end,
    })

    -- Also apply now for the initial colorscheme
    make_transparent()
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "${colors.bg1}" })
    boost_light_contrast()
  '';
}
