{username, ...}: {
  imports = [../modules/home.nix];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles.context = {
    host = "tmonaghan";
    role = {
      desktop = true;
    };
  };
}
