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
          date_format = "%Y-%m-%d";
          template = null;
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
      action = "<cmd>Obsidian quick-switch<CR>";
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
      key = "<leader>ot";
      action = "<cmd>Obsidian tags<CR>";
      options.desc = "[O]bsidian [T]ags";
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
      action = "<cmd>Obsidian link-new<CR>";
      options.desc = "[O]bsidian [N]ew linked note from selection";
    }
  ];
}
