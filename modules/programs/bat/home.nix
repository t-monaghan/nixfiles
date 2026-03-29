{config, lib, ...}:
lib.mkIf config.nixfiles.programs.bat.enable {
  programs.bat = {
    enable = true;
    config = {
      theme-dark = "gruvbox-dark";
      theme-light = "gruvbox-light";
    };
  };
}
