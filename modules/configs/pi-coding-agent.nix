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
    packages = ["npm:pi-mcp-adapter" "npm:pi-sandbox"];
    quietStartup = true;
    warnings.anthropicExtraUsage = false;
  };
in {
  home.packages = [
    pkgs.pi-coding-agent
    pkgs.nodejs
  ];
  options.nixfiles.pi.providerSettings = lib.mkOption {
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

  config.home.file.".pi/agent/settings.json".text =
    builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
}
