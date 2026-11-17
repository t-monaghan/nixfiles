{
  config,
  lib,
  pkgs,
  ...
}: let
  ctx = config.nixfiles.context;
in {
  imports = [
    ./context.nix
    ./theme
    ./tools/fish.nix
    ./tools/git.nix
    ./tools/mcp.nix
    ./tools/rex.nix
    ./tools/sesh.nix
    ./tools/starship.nix
    ./tools/television.nix
    ./tools/tmux.nix
  ];

  home.packages =
    (with pkgs; [
      eza
      jq
      curl
      wget
      tree
      killport
      fblog
      hyperfine
      watchexec
    ])
    ++ lib.optionals ctx.role.work (with pkgs; [
      jira-cli-go
      buildkite-cli
    ]);

  programs = {
    ripgrep.enable = true;
    fd.enable = true;
    go.enable = true;

    bat = {
      enable = true;
      config = {
        theme = "base16";
      };
    };

    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
      historyWidget.command = "";
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    atuin = {
      enable = true;
      settings = {
        enter_accept = true;
        filter_mode_shell_up_key_binding = "session";
        workspaces = true;
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global = {
        hide_env_diff = true;
        warn_timeout = "1h";
      };
    };

    uv.enable = lib.mkIf (ctx.role.desktop || ctx.role.work) true;
    awscli.enable = lib.mkIf ctx.role.work true;
    granted.enable = lib.mkIf ctx.role.work true;
  };
}
