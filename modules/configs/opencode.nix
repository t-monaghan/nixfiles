{pkgs, lib, ...}: {
  enable = true;
  settings = {
    model = "github-copilot/claude-opus-4.6";
    small_model = "github-copilot/gpt-5-mini";
    enabled_providers = ["github-copilot"];
    autoupdate = false;
    share = "disabled";
    default_agent = "plan";
    formatter = {
      nixfmt = {
        command = ["${lib.getExe pkgs.nixfmt}"];
        patterns = ["*.nix"];
      };
      treefmt = {
        command = ["${lib.getExe pkgs.treefmt}"];
        patterns = ["*"];
      };
    };
    compaction = {
      auto = true;
      prune = true;
    };
    watcher = {
      ignore = [
        "**/node_modules/**"
        "**/dist/**"
        "**/.git/**"
        "**/result/**"
        "**/.direnv/**"
      ];
    };
    permission = {
      bash = {
        allow = [
          "gh pr create:*"
          "gh pr comment:*"
          "gh pr view:*"
          "gh pr list:*"
          "gh pr diff:*"
          "gh pr checks:*"
          "gh pr checkout:*"
          "gh pr merge:*"
          "gh issue list:*"
          "gh issue view:*"
          "gh issue create:*"
          "gh issue comment:*"
          "gh repo view:*"
          "gh run list:*"
          "gh run view:*"
          "gh run watch:*"
        ];
      };
    };
  };
}
