{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.claude-code.enable {
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;
  };
}
