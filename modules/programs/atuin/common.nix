{lib, ...}: {
  options.nixfiles.programs.atuin.enable = lib.mkEnableOption "atuin";
}
