# Pi coding agent configuration (all environments).
#
# Base settings, extensions, sandbox, dispatch, MCP, and context overrides
# (desktop vs headless, work profile, homelab MCP) all live in this file.
{
  config,
  lib,
  pkgs,
  ...
}: let
  ctx = config.nixfiles.context;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  sandboxSource = ./pi-sandbox;
  sandboxDir = "${config.home.homeDirectory}/.local/share/pi/extensions/sandbox";
  installSandbox = pkgs.writeShellScript "install-pi-sandbox" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.nodejs pkgs.coreutils pkgs.git]}:$PATH
    source=${sandboxSource}
    target=${lib.escapeShellArg sandboxDir}
    revision="$source:${pkgs.nodejs}"

    if [ -f "$target/.installed-revision" ] &&
       [ "$(cat "$target/.installed-revision")" = "$revision" ] &&
       [ -d "$target/node_modules" ]; then
      exit 0
    fi

    mkdir -p "$target"
    rm -f "$target/.installed-revision"
    cp -R --no-preserve=mode "$source/." "$target/"
    cd "$target"
    npm ci --include=dev --ignore-scripts=false --no-audit --no-fund
    printf '%s\n' "$revision" > .installed-revision
  '';
  sharedPiSettings = {
    defaultThinkingLevel = "medium";
    treeFilterMode = "no-tools";
    packages = [sandboxDir "${pkgs.pi-question}"] ++ config.nixfiles.pi.packages;
    quietStartup = true;
    fullscreenCopyOnSelect = config.nixfiles.pi.fullscreenCopyOnSelect;
    warnings.anthropicExtraUsage = false;
    doubleEscapeAction = "fork";
    markdown.codeBlockIndent = "";
  };
in {
  options.nixfiles.pi = {
    fullscreenCopyOnSelect = lib.mkOption {
      type = lib.types.bool;
      default = ctx.role.desktop;
      description = "Copy selected text automatically in pi fullscreen mode.";
    };
    providerSettings = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        Pi provider/model settings merged into the shared settings.json.
        Defaults to the personal (GitHub Copilot) profile; overridden when
        nixfiles.context.role.work is enabled.
      '';
      default =
        if ctx.role.work
        then {
          defaultProvider = "github-copilot";
          defaultModel = "gemini-4-argon";
          enabledModels = [
            "github-copilot/gpt-6.1-sol"
            "anthropic/claude-fable-5-1"
            "github-copilot/gpt-6-astra"
            "github-copilot/kimi-k3"
          ];
        }
        else {
          defaultProvider = "github-copilot";
          defaultModel = "gpt-6.1-sol";
          enabledModels =
            lib.optional (ctx.host == "dolomite") "github-copilot/gpt-6.1-sol"
            ++ [
              "github-copilot/gpt-6-astra"
              "github-copilot/kimi-k3"
            ];
        };
    };
    packages = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = lib.optionals ctx.role.work [
        "git:github.com/cultureamp/sre-health-triage@tfm/end-to-end"
        "git:github.com/cultureamp/sre-ai-toolkit@fix/aws-health-event-author-triage"
        "git:github.com/cultureamp/ca-agent-context@main"
      ];
      example = ["git:github.com/org/skills@main"];
      description = ''
        Extra pi package sources (npm, git, or path). Lists from several
        modules are concatenated, so work profiles can add their own
        private skill repositories. Git sources are cloned by pi into
        ~/.pi/agent/git/ and refreshed with `pi update --extensions`.
      '';
    };
    homeAssistantMcp = lib.mkOption {
      type = lib.types.bool;
      default = ctx.role.homelab;
      description = "Whether to enable the Home Assistant MCP server.";
    };
    dispatchModel = lib.mkOption {
      type = lib.types.str;
      default = "github-copilot/kimi-k3";
      description = "Default model for asynchronous worktree agents.";
    };
  };

  config.home = let
    agentRoot = "${config.home.homeDirectory}/dev/agents";
  in
    lib.mkMerge [
      {
        activation.piSandboxInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
          run ${installSandbox}
        '';
        file.".pi/agent/settings.json".text =
          builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
        file.".pi/agent/mcp.json".text = builtins.toJSON {
          mcpServers =
            (lib.mapAttrs (name: server:
              lib.filterAttrs (_: value: value != null && value != [] && value != {})
              (builtins.removeAttrs server ["auth" "lifecycle"])
              // lib.optionalAttrs (name == "atlassian") {
                url = "https://mcp.atlassian.com/v1/mcp";
              })
            config.programs.mcp.servers)
            // lib.optionalAttrs config.nixfiles.pi.homeAssistantMcp {
              home-assistant = {
                url = "https://hass.dolomite.lan/api/mcp";
                oauth = {
                  clientId = "http://127.0.0.1:8765/";
                  callbackPort = 8765;
                };
              };
            };
        };
        file.".pi/agent/dispatch.json".text = builtins.toJSON {
          inherit agentRoot;
          repoRoot = "${config.home.homeDirectory}/dev";
          model = config.nixfiles.pi.dispatchModel;
          maxConcurrent = 5;
        };
        file."dev/agents/.pi/sandbox.json".text = builtins.toJSON {
          filesystem.allowWrite = [agentRoot];
        };
        file.".pi/agent/AGENTS.md".text =
          if isDarwin
          then ''
            ${builtins.readFile ./agent-context/shared.md}

            ${builtins.readFile ./agent-context/pi.md}

            ${builtins.readFile ./agent-context/macos.md}
          ''
          else ''
            ${builtins.readFile ./agent-context/shared.md}

            ${builtins.readFile ./agent-context/pi.md}
          '';
        activation.piDispatchDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p ${lib.escapeShellArg agentRoot}/worktrees ${lib.escapeShellArg agentRoot}/sessions
        '';
        packages =
          [
            pkgs.pi-coding-agent
            pkgs.nodejs
            (pkgs.writeShellScriptBin "pi-hud" ''
              export PI_HUD_PI=${pkgs.pi-coding-agent}/bin/pi
              exec ${pkgs.nodejs}/bin/node ${./pi-hud.mjs} "$@"
            '')
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            # @anthropic-ai/sandbox-runtime resolves these by executable name at
            # startup. They are required for filesystem and network isolation.
            pkgs.bubblewrap
            pkgs.socat
          ];
      }
      (lib.mkIf ctx.role.desktop {
        sessionVariables.PI_SKIP_VERSION_CHECK = "1";
        file.".pi/agent" = {
          source = ./pi-coding-agent;
          recursive = true;
        };
      })
      (lib.mkIf (!ctx.role.desktop) {
        file.".pi/agent/sandbox.json".source = ./pi-coding-agent/sandbox.json;
      })
    ];
}
