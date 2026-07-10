{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.work.cultureAmp.enable {
  # Work profile uses Anthropic only; overrides the shared pi config default
  # (GitHub Copilot). See modules/configs/pi-coding-agent.nix.
  nixfiles.pi.providerSettings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-8";
    enabledModels = [
      "github-copilot/claude-opus-4.8"
      "github-copilot/claude-sonnet-4.6"
      "anthropic/claude-opus-4-8"
      "anthropic/claude-sonnet-4-6"
    ];
  };

  home.packages = with pkgs; [
    jira-cli-go
    buildkite-cli
  ];
  programs = {
    uv.enable = true;
    awscli.enable = true;
    mise.enable = true;

    granted = {
      enable = true;
      enableFishIntegration = false;
    };

    fish = {
      interactiveShellInit = "set -gx _ZO_EXCLUDE_DIRS $HOME/hotel";
      shellAbbrs = {
        "hsu" = "hotel services up";
        "hsl" = "hotel services logs --follow --all";
        "hsd" = "hotel services down";
        "hsls" = "hotel services list";
      };
      functions = {
        clone = {
          description = "Clone a cultureamp repo";
          body = ''
            if set -q argv[2]
                git clone https://github.com/cultureamp/"$argv[1]" "$argv[2..-1]"
            else
                git clone https://github.com/cultureamp/"$argv[1]"
                cd "$argv[1]"
            end
          '';
        };
      };
    };

    mcp.servers = {
      hotel-mcp = {
        command = "hotel";
        args = ["mcp-server"];
        lifecycle = "lazy";
      };
      harness = {
        command = "npx";
        args = ["-y" "harness-mcp-v2"];
        env = {
          HARNESS_API_KEY = "\${HARNESS_PLATFORM_API_KEY}";
        };
        lifecycle = "lazy";
      };
      atlassian = {
        url = "https://mcp.atlassian.com/v1/sse";
        auth = "oauth";
      };
      buildkite-readonly = {
        url = "https://mcp.buildkite.com/mcp/readonly";
        auth = "oauth";
      };
      glean = {
        url = "https://culture-amp-be.glean.com/mcp/default";
        auth = "oauth";
      };
      imds-broker = {
        command = "imds-broker";
        args = [
          "mcp"
          "--profile-filter"
          "^cultureamp(?:-.+)?/.*(ReadOnly|ViewOnly|Cost)"
        ];
      };
      aws-research = {
        url = "https://knowledge-mcp.global.api.aws";
      };
    };
  };
}
