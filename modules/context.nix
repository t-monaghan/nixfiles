{
  lib,
  pkgs,
  ...
}: {
  options.nixfiles = {
    context = {
      host = lib.mkOption {
        type = lib.types.enum ["tom.monaghan1" "tmonaghan" "dolomite"];
        description = "Host identifier for this configuration.";
      };
      role = {
        desktop = lib.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.hostPlatform.isDarwin;
          description = "Enable GUI desktop applications and window management.";
        };
        work = lib.mkEnableOption "Culture Amp work environment";
        homelab = lib.mkEnableOption "Homelab integrations (Home Assistant, dolomite services)";
      };
      flakePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Store path of this flake when evaluating from a flake-backed host.";
      };
    };
  };
}
