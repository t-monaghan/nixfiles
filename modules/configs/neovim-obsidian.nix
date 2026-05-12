{pkgs, ...}: {
  plugins = {
    obsidian = {
      enable = true;
      settings = {
        workspaces = [
          {
            name = "notes";
            path = "~/notes";
          }
        ];
        completion = {
          nvim_cmp = false;
          blink = true;
          min_chars = 2;
        };
        new_notes_location = "current_dir";
        note_id_func.__raw = ''
          function(title)
            if title ~= nil then
              return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
              return tostring(os.time())
            end
          end
        '';
        daily_notes = {
          folder = "daily";
          date_format = "%y-%m-%d";
          alias_format = "%-d-%b-%y";
          template = "daily.md";
        };
        templates = {
          folder = "templates";
        };
        ui = {
          enable = true;
        };
        checkbox = {
          order = [" " "x"];
          toggles = {
            " " = {
              char = "󰄱";
              hl_group = "ObsidianTodo";
            };
            "x" = {
              char = "";
              hl_group = "ObsidianDone";
            };
          };
        };
        legacy_commands = false;
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>on";
      action = "<cmd>Obsidian new<CR>";
      options.desc = "[O]bsidian [N]ew note";
    }
    {
      mode = "n";
      key = "<leader>oo";
      action = "<cmd>Obsidian quick_switch<CR>";
      options.desc = "[O]bsidian [O]pen note";
    }
    {
      mode = "n";
      key = "<leader>os";
      action = "<cmd>Obsidian search<CR>";
      options.desc = "[O]bsidian [S]earch";
    }
    {
      mode = "n";
      key = "<leader>od";
      action = "<cmd>Obsidian today<CR>";
      options.desc = "[O]bsidian [D]aily note";
    }
    {
      mode = "n";
      key = "<leader>ob";
      action = "<cmd>Obsidian backlinks<CR>";
      options.desc = "[O]bsidian [B]acklinks";
    }
    {
      mode = "n";
      key = "<leader>ol";
      action = "<cmd>Obsidian links<CR>";
      options.desc = "[O]bsidian [L]inks";
    }
    {
      mode = "n";
      key = "<leader>ox";
      action = "<cmd>Obsidian toggle_checkbox<CR>";
      options.desc = "[O]bsidian toggle checkbo[x]";
    }
    {
      mode = "n";
      key = "<leader>oT";
      action = "<cmd>Obsidian tags<CR>";
      options.desc = "[O]bsidian [T]ags";
    }
    {
      mode = "n";
      key = "<leader>op";
      action = "<cmd>Obsidian yesterday<CR>";
      options.desc = "[O]bsidian [P]revious";
    }
    {
      mode = "n";
      key = "<leader>ot";
      action.__raw = ''
        function()
          local entry_display = require('telescope.pickers.entry_display')
          require('telescope.builtin').grep_string({
            search = '- [ ]',
            cwd = vim.fn.expand('~/notes/daily'),
            prompt_title = 'Open Todos',
            only_sort_text = true,
            disable_coordinates = true,
            entry_maker = function(entry)
              local _, _, filename, lnum, col, text = string.find(entry, '(.+):(%d+):(%d+):(.*)')
              if not filename then return nil end
              return {
                value = entry,
                display = vim.trim(text),
                ordinal = vim.trim(text),
                filename = require('plenary.path'):new(vim.fn.expand('~/notes'), filename):absolute(),
                lnum = tonumber(lnum),
                col = tonumber(col),
              }
            end,
          })
        end
      '';
      options.desc = "[O]bsidian open [t]odos";
    }
    {
      mode = "v";
      key = "<leader>ol";
      action = "<cmd>Obsidian link<CR>";
      options.desc = "[O]bsidian [L]ink selection";
    }
    {
      mode = "v";
      key = "<leader>on";
      action = "<cmd>Obsidian link_new<CR>";
      options.desc = "[O]bsidian [N]ew linked note from selection";
    }
  ];
}
