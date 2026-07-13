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
      action.__raw = ''
        function()
          local search = require('obsidian.search')
          local util = require('obsidian.util')
          local api = require('obsidian.api')
          local log = require('obsidian.log')

          local dir = api.resolve_workspace_dir()
          local tag = api.cursor_tag()
          local tags = tag and { tag } or {}

          local function gather_sorted(tag_locations, filter_tags)
            local entries = {}
            for _, tag_loc in ipairs(tag_locations) do
              for _, t in ipairs(filter_tags) do
                if tag_loc.tag:lower() == t:lower() or vim.startswith(tag_loc.tag:lower(), t:lower() .. "/") then
                  local display = string.format("%s [%s] %s", tag_loc.note:display_name(), tag_loc.line, tag_loc.text)
                  local mtime = vim.fn.getftime(tostring(tag_loc.path))
                  entries[#entries + 1] = {
                    value = { path = tag_loc.path, line = tag_loc.line, col = tag_loc.tag_start },
                    display = display,
                    ordinal = display,
                    filename = tostring(tag_loc.path),
                    lnum = tag_loc.line,
                    col = tag_loc.tag_start,
                    mtime = mtime,
                  }
                  break
                end
              end
            end
            if vim.tbl_isempty(entries) then
              log.warn("Tag(s) not found")
              return
            end
            table.sort(entries, function(a, b)
              if a.mtime ~= b.mtime then return a.mtime > b.mtime end
              return a.filename > b.filename
            end)
            vim.schedule(function()
              Obsidian.picker.pick(entries, { prompt_title = "#" .. table.concat(filter_tags, ", #") })
            end)
          end

          if not vim.tbl_isempty(tags) then
            search.find_tags_async(tags, function(tag_locations)
              gather_sorted(tag_locations, util.tbl_unique(tags))
            end, { dir = dir })
          else
            search.find_tags_async("", function(tag_locations)
              local all_tags = {}
              local seen = {}
              for _, tl in ipairs(tag_locations) do
                if not seen[tl.tag] then
                  seen[tl.tag] = true
                  all_tags[#all_tags + 1] = tl.tag
                end
              end
              vim.schedule(function()
                Obsidian.picker.pick(all_tags, {
                  callback = function(...)
                    local selected = vim.tbl_map(function(v) return v.user_data end, { ... })
                    gather_sorted(tag_locations, selected)
                  end,
                  selection_mappings = Obsidian.picker._tag_selection_mappings(),
                  allow_multiple = true,
                })
              end)
            end, { dir = dir })
          end
        end
      '';
      options.desc = "[O]bsidian [T]ags (newest first)";
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
