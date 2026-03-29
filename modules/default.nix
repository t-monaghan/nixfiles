# Root Nixfiles Module
# Auto-imports all common.nix and home.nix files in the module tree.
# Declares the top-level nixfiles options.
{
  config,
  lib,
  ...
}:
{
  imports =
    lib.pipe ./. [
      lib.filesystem.listFilesRecursive
      (lib.filter (lib.strings.hasSuffix "common.nix"))
    ]
    ++ lib.pipe ./. [
      lib.filesystem.listFilesRecursive
      (lib.filter (lib.strings.hasSuffix "home.nix"))
    ];

  options.nixfiles = {
    enable = lib.mkEnableOption "the Nixfiles module";
  };

  config = lib.mkIf config.nixfiles.enable {
    nix.gc.automatic = true;
    programs.home-manager.enable = true;
    home.stateVersion = "23.11";
    home.shell.enableFishIntegration = true;

    services.home-manager.autoExpire = {
      enable = true;
      store.cleanup = true;
    };
  };
}
