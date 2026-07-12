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
  lib,
  ...
}: let
  colors = import ./configs/colours.nix;
in {
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

  programs = {
    fish = import ./configs/fish.nix {inherit pkgs lib colors;};

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
        theme-dark = colors.bat.dark;
        theme-light = colors.bat.light;
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = import ./configs/starship.nix {inherit colors;};
    };

    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
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

    tmux = import ./configs/tmux.nix {inherit pkgs lib colors;};

    sesh = {
      enable = true;
      enableAlias = false;
      enableTmuxIntegration = false;
      settings.default_session.preview_command = "eza --all --git-ignore --classify=always --color=always --icons=always --tree --level=2 --sort=old --git {}";
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
