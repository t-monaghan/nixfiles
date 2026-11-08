{
  config,
  lib,
  pkgs,
  ...
}: let
  trackSessions = pkgs.writeShellScript "rex-track-sessions" ''
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rex"
    ${lib.getExe' pkgs.coreutils "mkdir"} -p "$state_dir"
    unset REX_SESSION REX_BLOCK REX_CLIENT
    exec ${lib.getExe config.programs.rex.package} --autostart=false do ${./rex}/track-sessions.lua --all --fail-fast
  '';
in {
  programs = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    rex = {
      enable = config.nixfiles.context.role.desktop;
      config = ./rex/init.lua;
    };
  };

  xdg.configFile = {
    "rex/init.lua" = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
      source = ./rex/init.lua;
    };
    "rex/history.lua".source = ./rex/history.lua;
    "rex/dolomite.lua".source = ./rex/dolomite.lua;
  };

  launchd.agents.rex-session-history = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.nixfiles.context.role.desktop) {
    enable = true;
    config = {
      ProgramArguments = ["${trackSessions}"];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      ProcessType = "Background";
    };
  };
}
