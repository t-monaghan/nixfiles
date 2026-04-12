{username, ...}: {
  imports = [../modules];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles = {
    work.cultureAmp.enable = true;
  };

  wilma = {
    enable = true;
    profiles = {
      primary = "global.anthropic.claude-opus-4-6-v1";
      small = "global.anthropic.claude-haiku-4-5-20251001-v1:0";
    };
  };
}
