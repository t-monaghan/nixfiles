{lib, ...}: {
  options.nixfiles.programs.claude-code.enable = lib.mkEnableOption "claude-code";
}
