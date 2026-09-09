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
      (
        if pkgs.stdenv.isDarwin
        then sandboxDir
        else "npm:pi-sandbox"
      )
    ];
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
      defaultModel = "gpt-5.6-sol";
      enabledModels = [
        "github-copilot/gpt-5.6-sol"
        "github-copilot/kimi-k3"
      ];
    };
  };
  config.home = {
    activation.piSandboxInstall = lib.mkIf pkgs.stdenv.isDarwin (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${installSandbox}
      ''
    );
    file.".pi/agent/settings.json".text =
      builtins.toJSON (sharedPiSettings // config.nixfiles.pi.providerSettings);
    packages = [
      pkgs.pi-coding-agent
      pkgs.nodejs
    ];
  };
}
