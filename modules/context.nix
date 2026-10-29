{
  config,
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
      platform = lib.mkOption {
        type = lib.types.enum ["darwin" "linux"];
        default =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "darwin"
          else "linux";
        description = "Target operating system family.";
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

    # Backwards-compatible alias kept synced with nixfiles.context.role.work.
    work.cultureAmp.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.nixfiles.context.role.work;
      description = "Deprecated alias for nixfiles.context.role.work.";
    };
  };
}
