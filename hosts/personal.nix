{pkgs, ...}: {
  imports = [
    ../modules/home.nix
  ];
  home = with pkgs; {
    username = "tmonaghan";
    homeDirectory = "/Users/tmonaghan";
    packages = [
      devbox
    ];
  };
}
