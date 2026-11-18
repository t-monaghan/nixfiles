{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.context.role.desktop {
  home.activation.claudeCodeWorkSkills = lib.mkIf config.nixfiles.context.role.work (
    lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
      run ${pkgs.writeShellApplication {
        name = "install-claude-code-work-skills";
        runtimeInputs = [pkgs.git pkgs.coreutils];
        text = builtins.readFile ./claude-code-work-skills.sh;
      }}/bin/install-claude-code-work-skills \
        ${lib.escapeShellArg "${config.home.homeDirectory}/.local/share/claude-code/skills-repos"} \
        ${lib.escapeShellArg "${config.home.homeDirectory}/.claude/skills"}
    ''
  );

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = config.nixfiles.context.role.work;
    mutableSettings = true;
    skills = {
      running-scripts-and-commands = ./claude-code-skills/just.md;
    };

    context = ''
      ${builtins.readFile ./agent-context/shared.md}

      ${builtins.readFile ./agent-context/claude-code.md}
    '';

    mcpServers.atlassian = {
      url = "https://mcp.atlassian.com/v1/mcp";
    };

    settings = {
      spinnerVerbs = {
        mode = "replace";
        verbs = builtins.fromJSON (builtins.readFile ./pi-coding-agent/spinner-verbs.json);
      };
      model = "claude-opus-5-5";
      tui = "fullscreen";
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
      hooks.SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "mkdir -p /tmp/claude/zsh && echo 'export TMPPREFIX=/tmp/claude/zsh' >> \"$CLAUDE_ENV_FILE\"";
            }
          ];
        }
      ];
      sandbox = {
        autoAllowBashIfSandboxed = true;
        allowUnsandboxedCommands = false;
        filesystem = {
          read = {
            allowOnly = [
              "~/.config/gh/"
              "/etc/ssl/"
              "/private/etc/ssl/"
            ];
          };
        };
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
  };
}
