{
  enable = true;
  defaultEditor = true;
  themes = {
    tmonaghan = {
      inherits = "sonokai";
      "ui.background" = { fg = "white"; };
      "ui.linenr.selected" = "#9ed072";
      "ui.bufferline" = { bg = "none"; };
      "ui.cursor" = {
        bg = "#9ed072";
        modifiers = [ "dim" ];
      };
      "ui.bufferline.active" = { modifiers = [ "reversed" ]; };
      "ui.selection.primary" = { modifiers = [ "reversed" ]; };
      "ui.statusline" = { bg = "none"; };
      "ui.popup" = { bg = "#3b3b3b"; };
      "ui.window" = { bg = "none"; };
      "ui.menu" = { bg = "none"; };
      "ui.help" = { bg = "none"; };
    };
  };
  languages = {
    language = [
      {
        name = "json";
        auto-format = false;
      }
      {
        name = "nix";
        auto-format = true;
        formatter = {
          command = "nixpkgs-fmt";
        };
      }
    ];
  };
  settings = {
    theme = "tmonaghan";
    editor = {
      line-number = "relative";
      bufferline = "always";
      true-color = true;
    };
    editor.statusline = {
      left = [ "spacer" "version-control" "position" "mode" "diagnostics" ];
      right = [ "workspace-diagnostics" "file-name" "total-line-numbers" "spinner" ];
    };
    keys.insert = {
      j.k = "normal_mode";
      C-l = [ "goto_line_end" ":append-output echo -n ';'" "normal_mode" ];
    };
    keys.normal = {
      space.F = "file_picker";
      space.f = "file_picker_in_current_directory";
    };
    editor.file-picker = {
      hidden = false;
    };
  };
}
