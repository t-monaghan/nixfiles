{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.claude-code.enable {
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;

    memory.text = ''
      Never coauthor any git/github operations with claude.

      ## PR Format

      PR descriptions should include the following sections:

      - **Problem** — What issue or need does this address?
      - **Why this change** — Why is this the right approach?
      - **Other changes** (optional) — Include this section when there are unusual or supplementary changes bundled in the PR (e.g. adding the multi-gitter flake, tooling updates, config changes unrelated to the main purpose).
    '';

    mcpServers.atlassian = {
      url = "https://mcp.atlassian.com/v1/mcp";
    };

    settings = {
      env = {
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_TELEMETRY = "1";
        TMPPREFIX = "/tmp/claude/zsh";
      };
      permissions = {
        allow = [
          "WebFetch"
          "Bash(git show:*)"
          "Bash(git log:*)"
          "Bash(git diff:*)"
          "Bash(git blame:*)"
          "Bash(git status:*)"
          "Bash(git stash list:*)"
          "Bash(git remote -v:*)"
          "Bash(git tag -l:*)"
          "Bash(gh pr view:*)"
          "Bash(gh pr list:*)"
          "Bash(gh pr diff:*)"
          "Bash(gh pr checks:*)"
          "Bash(gh issue view:*)"
          "Bash(gh issue list:*)"
          "Bash(gh repo view:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(less:*)"
          "Bash(file:*)"
          "Bash(wc:*)"
          "Bash(ls:*)"
          "Bash(find:*)"
          "Bash(tree:*)"
          "Bash(which:*)"
          "Bash(whoami:*)"
          "Bash(pwd:*)"
          "Bash(echo:*)"
          "Bash(env:*)"
          "Bash(du:*)"
          "Bash(df:*)"
          "Bash(stat:*)"
          "Read"
          "mcp__context7__resolve-library-id"
          "mcp__context7__get-library-docs"
          "Edit(~/go/pkg)"
          "Edit(~/.gradle/)"
          "Edit(~/.npm/)"
          "Edit(~/Library/Caches/go-build)"
          "Edit(~/Library/Caches/golangci-lint)"
          "Edit(~/.cache/)"
          "Edit(~/.local/state/mise/)"
          "Edit(~/.local/share/direnv/)"
          "Edit(~/Library/Caches/)"
          "Edit(/Users/brew/Library/Caches/)"
        ];
      };
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
      };
      hooks = {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "mkdir -p /tmp/claude/zsh && echo 'export TMPPREFIX=/tmp/claude/zsh' >> \"$CLAUDE_ENV_FILE\"";
              }
            ];
          }
        ];
        Notification = [
          {
            matcher = "permission_prompt";
            hooks = [
              {
                type = "command";
                command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \*\ *) ;; *) tmux set-environment -t "$session" CLAUDE_ORIGINAL_SESSION "$session" && tmux rename-session -t "$session" "* $session *";; esac; fi'';
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \*\ *) ;; *) tmux set-environment -t "$session" CLAUDE_ORIGINAL_SESSION "$session" && tmux rename-session -t "$session" "* $session *";; esac; fi'';
              }
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); original=$(tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n "$original" ]; then tmux rename-session -t "$session" "$original" && tmux set-environment -t "$original" -u CLAUDE_ORIGINAL_SESSION; fi; fi'';
              }
            ];
          }
        ];
        SessionEnd = [
          {
            hooks = [
              {
                type = "command";
                command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); original=$(tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n "$original" ]; then tmux rename-session -t "$session" "$original" && tmux set-environment -t "$original" -u CLAUDE_ORIGINAL_SESSION; fi; fi'';
              }
            ];
          }
        ];
      };
      sandbox = {
        autoAllowBashIfSandboxed = true;
        allowUnsandboxedCommands = false;
        network = {
          allowedDomains = [
            "registry.npmjs.org"
            "proxy.golang.org"
            "sum.golang.org"
            "storage.googleapis.com"
            "github.com"
            "api.github.com"
            "raw.githubusercontent.com"
          ];
          allowUnixSockets = [
            "/nix/var/nix/daemon-socket/socket"
            "/tmp/claude/tsx-*"
          ];
          allowLocalBinding = true;
        };
      };
      statusLine = {
        type = "command";
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); session_name=$(echo \"$input\" | jq -r '.session_name // empty'); used=$(echo \"$input\" | jq -r '.context_window.used_percentage // empty'); worktree=$(echo \"$input\" | jq -r '.worktree.name // empty'); dir=$(basename \"$cwd\"); out=\"$(printf '\\033[1;36m%s\\033[0m' \"$dir\")\"; if git -C \"$cwd\" rev-parse --git-dir >/dev/null 2>&1; then branch=$(git -C \"$cwd\" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null); [ -n \"$branch\" ] && out=\"$out $(printf '\\033[33m  %s\\033[0m' \"$branch\")\"; status=$(git -C \"$cwd\" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false status --porcelain 2>/dev/null); if [ -n \"$status\" ]; then mod=$(echo \"$status\" | grep -c '^ M\\|^M'); unt=$(echo \"$status\" | grep -c '^??'); stg=$(echo \"$status\" | grep -c '^[MADRC]'); st=\"\"; [ \"$mod\" -gt 0 ] && st=\"\${st}󰏫 ($mod) \"; [ \"$unt\" -gt 0 ] && st=\"\${st}󰊇 ($unt) \"; [ \"$stg\" -gt 0 ] && st=\"\${st}󰶍 \"; [ -n \"$st\" ] && out=\"$out $(printf '\\033[33m%s\\033[0m' \"$st\")\"; fi; fi; [ -n \"$worktree\" ] && out=\"$out $(printf '\\033[35m 󰘬 %s\\033[0m' \"$worktree\")\"; [ -n \"$session_name\" ] && out=\"$out $(printf '\\033[32m󰆍 %s\\033[0m' \"$session_name\")\"; projdir=$(echo \"$input\" | jq -r '.workspace.project_dir // empty'); if [ -n \"$projdir\" ] && [ \"$(jq -r '.sandbox.enabled // false' \"$projdir/.claude/settings.local.json\" 2>/dev/null)\" = \"true\" ]; then out=\"$out $(printf '\\033[32m 󰒃 sandbox\\033[0m')\"; else out=\"$out $(printf '\\033[31m ✗ sandbox\\033[0m')\"; fi; [ -n \"$used\" ] && out=\"$out $(printf '\\033[2m %.0f%%\\033[0m' \"$used\")\"; echo \"$out\"";
      };
    };
  };
}
