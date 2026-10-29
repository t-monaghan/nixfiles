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
    host = "tmonaghan";
    inherit flakePath;
    role = {
      desktop = true;
    };
  };
}
