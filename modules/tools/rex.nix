{
  config,
  lib,
  pkgs,
  ...
}: let
  trackSessions = pkgs.writeShellScript "rex-track-sessions" ''
    rex_bin="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
    if [ ! -x "$rex_bin" ]; then
      echo "Rex Server is not installed" >&2
      exit 1
    fi
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rex"
    ${lib.getExe' pkgs.coreutils "mkdir"} -p "$state_dir"
    unset REX_SESSION REX_BLOCK REX_CLIENT
    exec "$rex_bin" --autostart=false do ${./rex}/track-sessions.lua --all --fail-fast
  '';
in {
  xdg.configFile = {
    "rex/init.lua".source = ./rex/init.lua;
    "rex/history.lua".source = ./rex/history.lua;
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
