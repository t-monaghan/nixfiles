# Meta-module: enables all default GUI programs.
{config, lib, ...}:
lib.mkIf config.nixfiles.programs.defaultGui.enable {
  nixfiles.programs = {
    aerospace.enable = true;
    ghostty.enable = true;
    alacritty.enable = true;
    jankyborders.enable = true;
    zed.enable = true;
  };
}
