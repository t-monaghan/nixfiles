{
  config,
  lib,
  pkgs,
  ...
}: let
  sessionPicker = pkgs.writeShellApplication {
    name = "rex-session-picker";
    runtimeInputs = [pkgs.fzf] ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin config.programs.rex.package;
    text = builtins.readFile ./rex/pick-session.sh;
  };
  worktreePicker = pkgs.writeShellApplication {
    name = "rex-worktree-picker";
    runtimeInputs = [pkgs.fzf pkgs.zoxide pkgs.jq pkgs.gh pkgs.git pkgs.fish pkgs.worktrunk]
      ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin config.programs.rex.package;
    text = ''
      export REX_WORKTREE_ROWS=${./rex/worktree-rows.jq}
      ${builtins.readFile ./rex/pick-worktree.sh}
    '';
  };
  shortcutsPopup = pkgs.writeShellApplication {
    name = "rex-shortcuts-popup";
    runtimeInputs = [pkgs.fzf pkgs.jq]
      ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin config.programs.rex.package;
    text = ''
      export REX_SHORTCUT_ROWS=${./rex/shortcut-rows.jq}
      ${builtins.readFile ./rex/show-shortcuts.sh}
    '';
  };
  sessionSettings = {
    picker = lib.getExe sessionPicker;
    worktree_picker = lib.getExe worktreePicker;
    shortcuts_popup = lib.getExe shortcutsPopup;
    sessions = let
      sessions = builtins.filter (session: session.name != "dolomite") (config.programs.sesh.settings.session or []);
      order = ["hud" "notes" "nixfiles"];
      names = order ++ builtins.filter (name: !(builtins.elem name order)) (map (session: session.name) sessions);
    in builtins.concatMap (name:
      map (session: {
        inherit (session) name path;
        startup_command = session.startup_command or "";
      }) (builtins.filter (session: session.name == name) sessions)
    ) names;
  };
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
    "rex/configured-sessions.lua".source = ./rex/configured-sessions.lua;
    "rex/session-settings.lua" = {
      text = ''
        return rex.json.decode([==[${builtins.toJSON sessionSettings}]==])
      '';
    };
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
