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
  sandboxSource = ./pi-sandbox;
  sandboxDir = "${config.home.homeDirectory}/.local/share/pi/extensions/sandbox";
  installSandbox = pkgs.writeShellScript "install-pi-sandbox" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.nodejs pkgs.coreutils pkgs.git]}:$PATH
    source=${sandboxSource}
    target=${lib.escapeShellArg sandboxDir}
    revision="$source:${pkgs.nodejs}"

    if [ -f "$target/.installed-revision" ] &&
       [ "$(cat "$target/.installed-revision")" = "$revision" ] &&
       [ -d "$target/node_modules" ]; then
      exit 0
    fi

    mkdir -p "$target"
    rm -f "$target/.installed-revision"
    cp -R --no-preserve=mode "$source/." "$target/"
    cd "$target"
    npm ci --include=dev --ignore-scripts=false --no-audit --no-fund
    printf '%s\n' "$revision" > .installed-revision
  '';
  sharedPiSettings = {
    defaultThinkingLevel = "medium";
    skills = ["~/.claude/skills"];
    treeFilterMode = "no-tools";
    packages = [
      "npm:pi-mcp-adapter"
      sandboxDir
    ];
    quietStartup = true;
    warnings.anthropicExtraUsage = false;
    doubleEscapeAction = "fork";
    markdown.codeBlockIndent = "";
  };
in {
  options.nixfiles.pi = {
    providerSettings = lib.mkOption {
      type = lib.types.attrs;
      description = ''
        Pi provider/model settings merged into the shared settings.json.
        Defaults to the personal (GitHub Copilot) profile; overridden by the
        Culture Amp work profile.
      '';
      default = {
        defaultProvider = "github-copilot";
        defaultModel = "gpt-6-sol";
        enabledModels = [
          "github-copilot/gpt-6-sol"
          "github-copilot/gpt-6-astra"
          "github-copilot/kimi-k3"
        ];
      };
    };
    dispatchModel = lib.mkOption {
      type = lib.types.str;
      default = "github-copilot/kimi-k3";
      description = "Default model for asynchronous worktree agents.";
    };
  };
  config.home = let
    agentRoot = "${config.home.homeDirectory}/dev/agents";
  in {
    activation.piSandboxInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${installSandbox}
    '';
    file.".pi/agent/settings.json".text =
      builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
    file.".pi/agent/dispatch.json".text = builtins.toJSON {
      inherit agentRoot;
      repoRoot = "${config.home.homeDirectory}/dev";
      model = config.nixfiles.pi.dispatchModel;
      maxConcurrent = 5;
    };
    file."dev/agents/.pi/sandbox.json".text = builtins.toJSON {
      filesystem.allowWrite = [agentRoot];
    };
    activation.piDispatchDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${lib.escapeShellArg agentRoot}/worktrees ${lib.escapeShellArg agentRoot}/sessions
    '';
    packages =
      [
        pkgs.pi-coding-agent
        pkgs.nodejs
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # @anthropic-ai/sandbox-runtime resolves these by executable name at
        # startup. They are required for filesystem and network isolation.
        pkgs.bubblewrap
        pkgs.socat
      ];
  };
}
