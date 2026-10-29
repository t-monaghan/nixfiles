{username, ...}: {
  imports = [../modules/home.nix];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
  };

  nixfiles.context = {
    host = "tom.monaghan1";
    role = {
      desktop = true;
      work = true;
    };
  };
}
