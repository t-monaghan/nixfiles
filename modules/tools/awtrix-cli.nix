{awtrix-cli, ...}: {
  imports = [awtrix-cli.homeManagerModules.default];

  programs.awtrix-cli = {
    enable = true;
    host = "192.168.1.97";
  };
}
