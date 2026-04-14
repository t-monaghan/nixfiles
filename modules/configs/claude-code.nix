{ ... }: {
  enable = true;
  skillsDir = ./claude-code-skills;

  memory.text = ''
    Never coauthor any git/github operations with claude.

    ## PR Format

    PR descriptions should include the following sections:

    - **Problem** — What issue or need does this address?
    - **Why this change** — Why is this the right approach?
    - **Other changes** (optional) — Include this section when there are unusual or supplementary changes bundled in the PR (e.g. adding the multi-gitter flake, tooling updates, config changes unrelated to the main purpose).

    ## OpenSpec

    This user uses [fission-ai/openspec](https://github.com/fission-ai/openspec) for spec-driven development. Run it with:

    ```bash
    npx @fission-ai/openspec@latest <command>
    ```

    Requires Node.js 20.19.0+.

    ### Common commands

    - `npx @fission-ai/openspec@latest init` — Initialize OpenSpec in a project
    - `npx @fission-ai/openspec@latest list` — List changes and specs
    - `npx @fission-ai/openspec@latest view` — Interactive terminal dashboard
    - `npx @fission-ai/openspec@latest validate` — Check artifacts for structural issues
    - `npx @fission-ai/openspec@latest archive` — Finalize completed changes
    - `npx @fission-ai/openspec@latest status` — Display artifact completion progress
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
        "Bash(diff:*)"
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
              command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \[*) ;; *) tmux set-environment -t "$session" CLAUDE_ORIGINAL_SESSION "$session" && tmux rename-session -t "$session" "[$session]";; esac; fi'';
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \[*) ;; *) tmux set-environment -t "$session" CLAUDE_ORIGINAL_SESSION "$session" && tmux rename-session -t "$session" "[$session]";; esac; fi'';
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \[*) original=$(tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n "$original" ]; then tmux set-environment -t "$session" -u CLAUDE_ORIGINAL_SESSION; tmux rename-session -t "$session" "$original"; fi;; esac; fi'';
            }
          ];
        }
      ];
      PostToolUse = [
        {
          hooks = [
            {
              type = "command";
              command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \[*) original=$(tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n "$original" ]; then tmux set-environment -t "$session" -u CLAUDE_ORIGINAL_SESSION; tmux rename-session -t "$session" "$original"; fi;; esac; fi'';
            }
          ];
        }
      ];
      SessionEnd = [
        {
          hooks = [
            {
              type = "command";
              command = ''if [ -n "$TMUX" ]; then session=$(tmux display-message -p '#{session_name}'); case "$session" in \[*) original=$(tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n "$original" ]; then tmux set-environment -t "$session" -u CLAUDE_ORIGINAL_SESSION; tmux rename-session -t "$session" "$original"; fi;; esac; fi'';
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
      command = "bash ${./claude-code-status-line.sh}";
    };
  };
}
