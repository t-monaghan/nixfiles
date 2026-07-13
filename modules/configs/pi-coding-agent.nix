# Pi coding agent settings.json.
#
# The shared settings live here; the per-profile provider/model difference is
# merged in via the `nixfiles.pi.providerSettings` option rather than a
# branching condition. The personal profile uses GitHub Copilot (the option
# default); the Culture Amp work profile overrides it with Anthropic (see
# modules/work/culture-amp/home.nix).
{
  config,
  lib,
  ...
}: let
  sharedPiSettings = {
    defaultThinkingLevel = "xhigh";
    skills = ["~/.claude/skills"];
    packages = ["npm:pi-mcp-adapter" "npm:pi-sandbox"];
    quietStartup = true;
    warnings.anthropicExtraUsage = false;
  };
in {
  options.nixfiles.pi.providerSettings = lib.mkOption {
    type = lib.types.attrs;
    description = ''
      Pi provider/model settings merged into the shared settings.json.
      Defaults to the personal (GitHub Copilot) profile; overridden by the
      Culture Amp work profile.
    '';
    default = {
      defaultProvider = "github-copilot";
      defaultModel = "claude-opus-4.6";
      enabledModels = [
        "github-copilot/claude-opus-4.6"
        "github-copilot/claude-sonnet-4.6"
        # "anthropic/claude-opus-4-6"
        # "anthropic/claude-sonnet-4-6"
      ];
    };
  };

  config.home.file.".pi/agent/settings.json".text =
    builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
}
