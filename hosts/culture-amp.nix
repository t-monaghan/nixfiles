{username, ...}: {
  imports = [../modules];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles = {
    work.cultureAmp.enable = true;
  };

}
