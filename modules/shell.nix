# Shared shell + CLI tooling — used by ALL three machines.
#
# This is a plain home-manager module (imported, not called) so it works
# identically on the standalone Mac home configs and on the home-manager
# instance running inside the `dolomite` NixOS system (see ../nixos/home.nix).
#
# Everything here is cross-platform; anything Mac-only (rancher-desktop PATH,
# nix-daemon sourcing, `open`/`caffeinate` abbrs, GUI apps) is either guarded by
# `pkgs.stdenv.isDarwin` in the imported config files or kept in the per-host
# module (e.g. ./home.nix for the Macs).
{
  pkgs,
  config,
  ...
}: {
  imports = [
    # `colors` + `fonts` as module arguments (used by the configs below).
    ./args.nix
    # One file per program; each sets its own `programs.<name>` block.
    ./configs/fish.nix
    ./configs/starship.nix
    ./configs/tmux.nix
  ];

  # CLI baseline shared across machines. Programs with their own home-manager
  # module (ripgrep, fd, bat, …) are configured below rather than listed here.
  home.packages = with pkgs; [
    eza
    jq
    curl
    wget
    tree
    killport
    fblog
    hyperfine
    watchexec
  ];

  # Keep worktrunk worktrees (…/repo/.worktrees/branch) out of the zoxide
  # database so `sesh list` / the tmux session picker aren't cluttered with
  # long worktree paths. Active worktrees still show up in the picker via
  # their tmux session name (e.g. `pi-<branch>`), which is the short handle
  # we actually want. Colon-separated globs; `**` crosses `/`.
  home.sessionVariables._ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}/**/.worktrees/**";

  programs = {
    # --- shell-integrated tooling -------------------------------------------
    ripgrep.enable = true;
    fd.enable = true;
    go.enable = true;

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };

    difftastic = {
      enable = true;
      git = {
        mode = "difftool";
        enable = true;
      };
    };

    git = {
      enable = true;
      signing.format = null;
      settings = {
        user.name = "t-monaghan";
        user.email = "tomaghan+git@gmail.com";
        push.autoSetupRemote = true;
        pull.rebase = true;
        init.defaultBranch = "main";
        pager.difftool = true;
        rerere.enabled = true;
        branch.sort = "-committerdate";
      };
      # .worktrees/ is where worktrunk (`wt`) creates in-repo worktrees; ignore
      # it everywhere so they never show as untracked / dirty the tree.
      ignores = [".DS_Store" ".worktrees/"];
    };

    bat = {
      enable = true;
      config = {
        # `base16` renders through ANSI 0–21 instead of hex, so bat follows the
        # terminal's palette — which Ghostty sets per appearance mode from
        # ./configs/colours.nix. One theme covers both modes, so there is no
        # theme-dark / theme-light to keep in step.
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

    sesh = {
      enable = true;
      enableAlias = false;
      enableTmuxIntegration = false;
      settings = {
        default_session.preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
        tui = {
          preview = true;
          show_icons = true;
          show_windows = true;
          preview_min_width = 80;
          preview_border = "line";
        };
      };
    };

    television = {
      enable = true;
      enableFishIntegration = true;
      channels = import ./configs/television-channels.nix;
      settings = import ./configs/television-settings.nix;
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = false;
      settings.indexes = ["nixpkgs" "home-manager" "nixos"];
    };

    navi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
