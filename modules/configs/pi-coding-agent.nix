# Pi coding agent settings.json.
#
# The shared settings live here; the per-profile provider/model difference is
# merged in via the `nixfiles.pi.providerSettings` option rather than a
# branching condition.
{
  config,
  lib,
  pkgs,
  ...
}: let
  sharedPiSettings = {
    defaultThinkingLevel = "medium";
    skills = ["~/.claude/skills"];
    treeFilterMode = "no-tools";
    packages = ["npm:pi-mcp-adapter" "npm:pi-sandbox"];
    quietStartup = true;
    warnings.anthropicExtraUsage = false;
  };
in {
  options.nixfiles.pi = {
    providerSettings = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        Pi provider/model settings merged into the shared settings.json.
        Defaults to the personal (GitHub Copilot) profile; overridden by the
        Culture Amp work profile.
      '';
      default = {
        defaultProvider = "github-copilot";
        defaultModel = "gpt-5.6-sol";
        enabledModels = [
          "github-copilot/gpt-5.6-sol"
          "github-copilot/kimi-k3"
        ];
      };
    };
    dispatchModel = lib.mkOption {
      type = lib.types.str;
      default = "github-copilot/kimi-k3";
      description = "Default model for asynchronous worktree agents.";
    };
  };
  config.home = let
    agentRoot = "${config.home.homeDirectory}/dev/agents";
  in {
    file.".pi/agent/settings.json".text =
      builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
    file.".pi/agent/dispatch.json".text = builtins.toJSON {
      inherit agentRoot;
      repoRoot = "${config.home.homeDirectory}/dev";
      model = config.nixfiles.pi.dispatchModel;
      maxConcurrent = 5;
    };
    file."dev/agents/.pi/sandbox.json".text = builtins.toJSON {
      filesystem.allowWrite = [agentRoot];
    };
    activation.piDispatchDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${lib.escapeShellArg agentRoot}/worktrees ${lib.escapeShellArg agentRoot}/sessions
    '';
    packages = [
      pkgs.pi-coding-agent
      pkgs.nodejs
    ];
  };
}
