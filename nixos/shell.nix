# Shell environment for the `dolomite` box — NON-FLAKE, no home-manager.
#
# Imported by dolomites-config.nix (uncomment `./shell.nix` there when ready).
# `programs.fish` and `programs.atuin` are already enabled in dolomites-config.nix;
# NixOS merges these definitions, so this file only *adds* to them.
#
# Only external dependency: ./lib/colours.nix (already present for neovim.nix).
{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = import ./lib/colours.nix;
in {
  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    eza
    bat
    fzf
    zoxide
    jq
    curl
    wget
    tree

    git
    gh
    difftastic

    television

    direnv
    nix-direnv
  ];

  environment.etc."gitconfig".text = ''
    [user]
    	name = t-monaghan
    	email = tomaghan+git@gmail.com
    [push]
    	autoSetupRemote = true
    [pull]
    	rebase = true
    [init]
    	defaultBranch = main
    [pager]
    	difftool = true
    [rerere]
    	enabled = true
    [branch]
    	sort = -committerdate
    [core]
    	excludesFile = /etc/gitignore
    [diff]
    	tool = difftastic
    [difftool]
    	prompt = false
    [difftool "difftastic"]
    	cmd = difft "$LOCAL" "$REMOTE"
    [credential "https://github.com"]
    	helper =
    	helper = !gh auth git-credential
    [credential "https://gist.github.com"]
    	helper =
    	helper = !gh auth git-credential
  '';
  environment.etc."gitignore".text = ''
    .DS_Store
    .worktrees/
  '';

  environment.variables.BAT_THEME = colors.bat.dark;

  environment.etc."direnv/direnvrc".text = ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';
  environment.etc."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
    warn_timeout = "1h"
  '';
  environment.sessionVariables.DIRENV_CONFIG = "/etc/direnv";

  #### starship ###############################################################
  programs.starship = {
    enable = true; # auto-adds fish integration
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      battery = {
        charging_symbol = "󰚥";
        display = [
          {
            discharging_symbol = "󱊣";
            style = colors.ok;
            threshold = 100;
          }
          {
            style = colors.ok;
            threshold = 75;
          }
          {
            discharging_symbol = "󱊢";
            style = colors.warn;
            threshold = 50;
          }
          {
            discharging_symbol = "󱊡";
            style = colors.warn;
            threshold = 20;
          }
          {
            discharging_symbol = "󰂃";
            style = colors.error;
            threshold = 0;
          }
        ];
        format = "[$symbol $percentage]($style) ";
        full_symbol = "󱊣";
        unknown_symbol = "󱈑";
      };
      character = {
        error_symbol = "[❯](${colors.error})";
        success_symbol = "[❯](bold ${colors.accent_alt})";
        vimcmd_symbol = "[ ](${colors.ok})";
        vimcmd_visual_symbol = "[ ](${colors.warn})";
      };
      custom = {
        aws_assumed_role = {
          command = ''
            if [[ -n $AWS_PROFILE ]]; then
              profile="$AWS_PROFILE"
            else
              profile="default"
            fi
            if [[ -n $AWS_REGION ]]; then
              region=" ($AWS_REGION)"
            else
              region=""
            fi
            echo "$profile$region"
          '';
          description = "Shows AWS profile and region when a role has been assumed";
          format = "[󰅟 $output ]($style)";
          shell = "/bin/bash";
          style = "bold ${colors.info}";
          when = "[[ -n $AWS_PROFILE ]]";
        };
        devbox = {
          command = "command_output=$(devbox version 2>&1)\nversion=$(echo \"$command_output\" | grep -E '^[0-9]+(\\.[0-9]+){2}$')\nif echo \"$command_output\" | grep -q \"Info: New devbox available:\"; then \n  update_version=$(echo \"$command_output\" | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' | sed -n '2p')\n  echo \"$version update available ($update_version)\" \nelse\n  echo \"$version\"\nfi\n";
          description = "Shows the devbox version if inside a devbox project";
          format = "[$symbol($output )]($style)";
          shell = "/bin/bash";
          style = "bold ${colors.info}";
          symbol = " ";
          when = "[[ -n $DEVBOX_INIT_PATH ]]\n";
        };
        direnv = {
          command = "if [[ -f ./devbox.json ]]; then\n  direnv_output=$(direnv status)\n  ## Confusingly, direnv has a status of 0 for allowed\n  if echo $direnv_output | grep -q \"Found RC allowed 0\"; then\n    echo \"\"\n  else\n    echo \" direnv is not allowed\"\n  fi\nfi\n";
          description = "Shows if direnv has not been allowed if inside a project with a .envrc and devbox.json";
          shell = "sh";
          when = "[[ -n $DIRENV_FILE ]]\n";
        };
      };
      directory = {style = "bold ${colors.accent_alt}";};
      format = "$directory$git_branch$git_status$git_state$direnv$java$golang$ruby$node$custom\n$status$character";
      git_branch = {
        style = colors.warn;
        symbol = " ";
      };
      git_status = {
        deleted = " ";
        format = "([$all_status$ahead_behind]($style))";
        modified = "󰏫 ($count) ";
        staged = "󰶍 ";
        stashed = "󰴮 ";
        style = colors.warn;
        untracked = "󰊇 ($count) ";
      };
      golang = {
        style = "bold ${colors.ok}";
        symbol = "󰟓 ";
      };
      java = {
        format = "[$symbol($version )]($style)";
        symbol = " ";
      };
      nix_shell = {
        disabled = false;
        format = "[$symbol$state( \\($name\\))]($style) ";
        symbol = "󰜗 ";
      };
      right_format = "$memory_usage$battery";
      ruby = {
        format = "[$symbol($version )]($style)";
        symbol = " ";
      };
      status = {
        disabled = false;
        format = "[$status]($style)";
      };
      time = {disabled = false;};
    };
  };

  #### atuin ##################################################################
  # `programs.atuin.enable` + settings.autosync live in dolomites-config.nix;
  # these merge with that. Fish integration is on by default.
  programs.atuin.settings = {
    enter_accept = true;
    filter_mode_shell_up_key_binding = "session";
    workspaces = true;
  };

  #### fish ###################################################################
  # `programs.fish.enable = true` already set in dolomites-config.nix.
  programs.fish = {
    loginShellInit = ''
      fish_add_path $HOME/.npm-global/bin
      fish_add_path $HOME/go/bin

      set -gx fish_color_autosuggestion ${colors.info}
      set -gx AWTRIX_HOST 192.168.1.97
      set -gx NPM_CONFIG_PREFIX "$HOME/.npm-global"

      bind \cx\ce edit_command_buffer
    '';

    # Tool integrations (NixOS has no per-tool fish modules for these; starship
    # and atuin wire themselves up via their own modules).
    interactiveShellInit = ''
      ${pkgs.zoxide}/bin/zoxide init fish | source
      ${pkgs.fzf}/bin/fzf --fish | source
      ${pkgs.direnv}/bin/direnv hook fish | source
      ${pkgs.navi}/bin/navi widget fish | source
      ${pkgs.television}/bin/tv init fish | source
    '';

    shellAbbrs = {
      s = "tv sesh --no-sort";
      nv = "nvim";
      nd = "nvim +'Obsidian today'";

      ci = "gh altar ci > /dev/null 2>&1 & disown";
      dismiss = "curl 'http://192.168.1.97/api/notify/dismiss'";
      n = "notify";
      stats = "curl 'http://192.168.1.97/api/stats' | jq";

      ns = "tv nix-search-tv";

      chmox = "chmod a+x";

      gco = "git checkout";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gpu = "git pull --autostash --rebase";
      gs = "git status";
      gl = "tv git-log";
      gd = "git diff";
      gdc = "git diff --cached";
      ga = "git add";
      gc = "git commit -m";
      ghpr = "gh pr checkout";
      gsc = "git stash clear";
      checks = "gh pr checks --required --watch";
      gsp = "git stash pop";
      gcob = "git checkout -b";
      grs = "git restore --staged";
      grim = "git rebase -i main";
      grm = "git rebase main";
      gap = "git add -p";
      gsl = "git stash list";
      gfm = "git fetch origin main:main";

      ll = "ls -ltra";

      dr = "devbox run";
      drs = "devbox run setup";
      drp = "devbox run populate";
      dsu = "devbox services up --pcflags '--keep-project'";
      reload = "rm -rf .devbox && direnv reload";
      hs = "hotel services";
      rmd = "rm -rf .devbox";

      rt = "trash-put";
      hlogs = "tail -f ~/.local/share/hotel/log.jsonl | fblog -m event";

      tf = "terraform";
      crl = "codex resume --last";
      clc = "claude --continue";
      pic = "pi --continue";
      pulls = "gh search prs --author=@me --state=open";

      oc = "opencode";
      occ = "opencode --continue";

      j = "just";
      jr = "just run";
      deploy-dev = "gh pr checks --watch --required && gh pr comment -b \".deploy to development\"";
      deploy-prod = "gh pr checks --watch --required && gh pr comment -b \".deploy\"";
    };

    plugins = [
      {inherit (pkgs.fishPlugins.foreign-env) name src;}
      {
        name = "pnpm-shell-completion";
        src = pkgs.fetchFromGitHub {
          owner = "g-plane";
          repo = "pnpm-shell-completion";
          rev = "v0.5.2";
          sha256 = "sha256-VCIT1HobLXWRe3yK2F3NPIuWkyCgckytLPi6yQEsSIE=";
        };
      }
    ];
  };
}
