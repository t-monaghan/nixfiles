# Meta-module: enables all default CLI tools.
{lib, ...}: {
  options.nixfiles.programs.defaultCli.enable =
    lib.mkEnableOption "default CLI tools";
}
