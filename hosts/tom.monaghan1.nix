{
  username,
  flakePath,
  ...
}: {
  imports = [../modules];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles.context = {
    host = "tom.monaghan1";
    inherit flakePath;
    role = {
      desktop = true;
      work = true;
    };
  };
}
