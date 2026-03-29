{lib, ...}: {
  options.nixfiles.programs.bat.enable = lib.mkEnableOption "bat";
}
