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

  nixfiles = {
    enable = true;

    programs = {
      defaultCli.enable = true;
      defaultGui.enable = true;
    };

    development.enable = true;
  };
}
