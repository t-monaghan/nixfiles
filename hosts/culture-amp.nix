{username, ...}: {
  imports = [../modules];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles = {
    enable = true;

    programs = {
      defaultCli.enable = true;
      defaultGui.enable = true;
    };

    development.enable = true;
    work.cultureAmp.enable = true;
  };
}
