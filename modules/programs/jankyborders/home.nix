{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.jankyborders.enable {
  services.jankyborders = {
    enable = true;
    settings = {
      active_color = "0xffcff1bf";
      hidpi = "on";
      width = 8;
    };
  };
}
