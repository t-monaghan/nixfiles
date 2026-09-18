{
  pkgs,
  username,
  ...
}: {
  imports = [../modules];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    packages = with pkgs; [
      devbox
    ];
  };

  nixfiles = {};
}
