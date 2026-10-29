{
  config,
  lib,
  ...
}: let
  ctx = config.nixfiles.context;
in {
  programs.mcp = lib.mkMerge [
    (lib.mkIf ctx.role.desktop {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    })
    (lib.mkIf ctx.role.work {
      servers = {
        agentsview = {
          command = "agentsview";
          args = ["mcp"];
        };
        hotel-mcp = {
          command = "hotel";
          args = ["mcp-server"];
          lifecycle = "lazy";
        };
        datadog = {
          url = "https://mcp.datadoghq.com/v1/mcp";
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
        slack = {
          description = "Slack hosted MCP — search, read, and send Slack messages";
          url = "https://mcp.slack.com/mcp";
          oauth = {
            clientId = "1601185624273.8899143856786";
            callbackUrl = "http://localhost:3118/callback";
          };
        };
      };
    })
  ];
}
