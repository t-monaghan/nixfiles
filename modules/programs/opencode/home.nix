{config, lib, ...}:
lib.mkIf config.nixfiles.programs.opencode.enable {
  programs.opencode = {
    enable = true;
    settings = {
      model = "github-copilot/claude-opus-4.6";
      small_model = "github-copilot/claude-haiku-4-5";
      enabled_providers = ["github-copilot"];
      autoupdate = false;
      share = "disabled";
      default_agent = "plan";
      formatter = {
        nixfmt = {
          command = ["nixfmt" "$FILE"];
          extensions = [".nix"];
        };
        treefmt = {
          command = ["treefmt" "--stdin" "$FILE"];
        };
      };
      compaction = {
        auto = true;
        prune = true;
      };
      watcher = {
        ignore = ["node_modules/**" "dist/**" ".git/**" "result/**" ".direnv/**"];
      };
      permission = {
        bash = {
          # gh read commands
          "gh pr view *" = "allow";
          "gh pr list *" = "allow";
          "gh pr diff *" = "allow";
          "gh pr checks *" = "allow";
          "gh pr status *" = "allow";
          "gh issue view *" = "allow";
          "gh issue list *" = "allow";
          "gh issue status *" = "allow";
          "gh repo view *" = "allow";
          "gh repo list *" = "allow";
          "gh run view *" = "allow";
          "gh run list *" = "allow";
          "gh workflow view *" = "allow";
          "gh workflow list *" = "allow";
          "gh release view *" = "allow";
          "gh release list *" = "allow";
          "gh search *" = "allow";
          "gh browse *" = "allow";
          "gh status" = "allow";
          "gh auth status *" = "allow";
        };
      };
    };
  };
}
