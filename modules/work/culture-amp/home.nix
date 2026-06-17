{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.work.cultureAmp.enable {
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
