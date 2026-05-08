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
          checkboxes = {
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
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>on";
      action = "<cmd>ObsidianNew<CR>";
      options.desc = "[O]bsidian [N]ew note";
    }
    {
      mode = "n";
      key = "<leader>oo";
      action = "<cmd>ObsidianQuickSwitch<CR>";
      options.desc = "[O]bsidian [O]pen note";
    }
    {
      mode = "n";
      key = "<leader>os";
      action = "<cmd>ObsidianSearch<CR>";
      options.desc = "[O]bsidian [S]earch";
    }
    {
      mode = "n";
      key = "<leader>od";
      action = "<cmd>ObsidianToday<CR>";
      options.desc = "[O]bsidian [D]aily note";
    }
    {
      mode = "n";
      key = "<leader>ob";
      action = "<cmd>ObsidianBacklinks<CR>";
      options.desc = "[O]bsidian [B]acklinks";
    }
    {
      mode = "n";
      key = "<leader>ol";
      action = "<cmd>ObsidianLinks<CR>";
      options.desc = "[O]bsidian [L]inks";
    }
    {
      mode = "n";
      key = "<leader>ot";
      action = "<cmd>ObsidianTags<CR>";
      options.desc = "[O]bsidian [T]ags";
    }
    {
      mode = "v";
      key = "<leader>ol";
      action = "<cmd>ObsidianLink<CR>";
      options.desc = "[O]bsidian [L]ink selection";
    }
    {
      mode = "v";
      key = "<leader>on";
      action = "<cmd>ObsidianLinkNew<CR>";
      options.desc = "[O]bsidian [N]ew linked note from selection";
    }
  ];
}
