# Meta-module: enables all default GUI programs.
{lib, ...}: {
  options.nixfiles.programs.defaultGui.enable =
    lib.mkEnableOption "default GUI programs";
}
