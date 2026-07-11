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

  # --- tmux helper scripts (ported from the mac tmux.nix) -------------------
  tmux-window-picker = pkgs.writeShellScript "tmux-window-picker" ''
    session="$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')"
    selected=$(${lib.getExe pkgs.tmux} list-windows -t "$session" -F '#{window_index}: #{pane_title}' \
      | ${lib.getExe pkgs.fzf} --no-sort --reverse --delimiter=':' \
        --preview "${lib.getExe pkgs.tmux} capture-pane -e -p -t '$session':{1} | tail -n \$FZF_PREVIEW_LINES" \
        --preview-window "right:80%")
    [ -n "$selected" ] && ${lib.getExe pkgs.tmux} select-window -t "$session:''${selected%%:*}"
  '';
  tmux-kill-session = pkgs.writeShellScript "tmux-kill-session" ''
    count=$(${lib.getExe pkgs.tmux} list-sessions | wc -l)
    [ "$count" -le 1 ] && exit 0
    target=$(${lib.getExe pkgs.tmux} display-message -p '#{session_name}')
    sesh last 2>/dev/null || ${lib.getExe pkgs.tmux} switch-client -n
    ${lib.getExe pkgs.tmux} kill-session -t "$target"
  '';
in {
  #### Packages ###############################################################
  # Tools referenced by the abbrs / functions / tmux config below. Work / CA
  # tools are left commented — uncomment the ones you actually want on this box.
  environment.systemPackages = with pkgs; [
    # core CLI
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
    # git + review
    git
    gh
    difftastic
    # shell tooling
    sesh
    television
    navi
    # direnv (+ nix-direnv, wired below)
    direnv
    nix-direnv

    # --- work / project tooling (uncomment as needed) ---
    # devbox        # dr/drs/drp/dsu/reload/rmd abbrs + starship devbox module
    # granted       # `assume` AWS role picker function
    # fblog         # `hlogs` abbr (hotel log tailing)
    # trash-cli     # `rt` abbr (trash-put)
    # (buildkite `bk` CLI — bkw/bkr/bko/bkl functions; package name varies)
  ];

  #### Git ####################################################################
  # No upstream NixOS `programs.git`; write the system-wide config directly.
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

  #### bat ####################################################################
  # gruvbox-dark is a bat built-in. (The mac config's "Monokai Pro Light" is a
  # custom theme; add it under ~/.config/bat/themes + `bat cache --build` and set
  # BAT_THEME_LIGHT/BAT_THEME_DARK if you want auto light/dark here too.)
  environment.variables.BAT_THEME = colors.bat.dark;

  #### direnv + nix-direnv ####################################################
  # No upstream NixOS `programs.direnv`. direnv reads its config dir from
  # $DIRENV_CONFIG, so point it at /etc/direnv and load nix-direnv globally.
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

  #### tmux ###################################################################
  # NixOS `programs.tmux` is thinner than home-manager's, so the HM options
  # (mouse / escapeTime / keyMode / customPaneNavigationAndResize) are expressed
  # as raw directives in extraConfig for portability.
  programs.tmux = {
    enable = true;
    historyLimit = 50000;
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse on
      set -sg escape-time 100
      setw -g mode-keys vi

      # customPaneNavigationAndResize (hjkl move, HJKL resize)
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g status off
      set -g detach-on-destroy off
      set -g pane-border-status top
      set -g pane-border-format ' #{?#{==:#{pane_current_command},fish},#{?#{m:\[*,#{session_name}},#[fg=${colors.warn}]#{session_name}#[default],#{session_name}},#{pane_title}} #{?window_zoomed_flag, #[fg=${colors.accent_alt} bold][ZOOMED]#[default],}#{?#{==:#{pane_index},0},#[align=right]#{S:#[default]─ #{?session_attached,#{?#{m:\[*,#{session_name}},#[fg=${colors.warn}],#[fg=${colors.ok}]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default],#{?#{m:\[*,#{session_name}},#[fg=${colors.orange}],#[dim]}#{session_name}#{?#{>:#{session_windows},1}, #{e|+:#{active_window_index},1}|#{session_windows},} #[default]}}#[default]──,}'
      bind -Tcopy-mode WheelUpPane send -N 0.25 -X scroll-up
      bind -Tcopy-mode WheelDownPane send -N 0.25 -X scroll-down

      # Vim-style visual selection in copy mode
      bind -Tcopy-mode-vi v send -X begin-selection
      bind -Tcopy-mode-vi y send -X copy-selection-and-cancel

      # Highlight active pane background when prefix is pressed
      bind -Troot C-b select-pane -P 'bg=${colors.bg1}' \; switch-client -Tprefix \; run -b 'sleep 1 && tmux select-pane -P bg=default'

      # Open sesh picker instead of default session tree
      unbind s
      bind s display-popup -E -w 50 -h 18 "sesh list -i | ${lib.getExe pkgs.fzf} --height=100% --no-sort --reverse --ansi | xargs -r sesh connect"

      # Switch windows via fzf picker (only if multiple windows)
      unbind w
      bind w if -F '#{?#{e|>:#{session_windows},1},1,}' 'display-popup -h 90% -w 90% -E "${tmux-window-picker}"' ""

      # Jump to last (MRU) window, or fall back to last session when there's only one window.
      bind -N "last-window-or-session" Tab if -F '#{?#{e|>:#{session_windows},1},1,}' 'last-window' 'switch-client -l'

      # Last session via sesh (only if multiple sessions)
      bind -N "last-session (via sesh)" a if-shell '[ $(tmux list-sessions | wc -l) -gt 1 ]' "run-shell 'sesh last'"

      # Kill current session and switch to previous
      bind X run-shell '${tmux-kill-session}'

      # Clone GitHub repo and open session
      bind g command-prompt -p "Clone GitHub repo ([org/]repo [dir]):" "run-shell -b 'tmux display-message \"Cloning %1...\" && fish -c \"ghclone %1\"'"

      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
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

    functions = {
      git-https = {
        description = "Changes the git remote to https from ssh";
        body = ''
          set current_url (git remote get-url origin)
          set new_url (echo $current_url | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
          git remote set-url origin https://github.com/$new_url
        '';
      };
      fish_greeting = {
        body = '''';
      };
      starship_transient_rprompt_func = {
        body = ''starship module time'';
      };
      gw = {
        wraps = ''gradle'';
        body = ''./gradlew $argv'';
      };
      mkcd = {
        body = ''mkdir $argv && cd $argv'';
      };
      # --- work / CA specific: notify (awtrix), wts/ghclone (worktrunk/sesh),
      # bk* (buildkite), assume (granted/AWS). Harmless when unused; trim freely.
      notify = {
        description = "Run a command and send AWTRIX notification on completion";
        body = ''
          set start (date +%s)
          $argv
          set cmd_status $status
          set elapsed (math (date +%s) - $start)

          if test $cmd_status -eq 0
            set colour "#00FF00"
            set text "DONE"
          else
            set colour "#FF0000"
            set text "FAILED"
          end

          curl -s -X POST "http://$AWTRIX_HOST/api/notify" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$text: $argv[1] ("$elapsed"s)\",\"color\":\"$colour\",\"duration\":10}" \
            > /dev/null 2>&1 &

          return $cmd_status
        '';
      };
      wts = {
        wraps = "wt switch";
        description = "wt switch, but open/attach a tmux session for the worktree (named by branch) instead of cd-ing into it";
        body = ''
          wt switch --no-cd -x sh $argv -- -c 'tmux has-session -t "$1" 2>/dev/null || tmux new-session -d -s "$1" -c "$2"; if [ -n "$TMUX" ]; then exec tmux switch-client -t "$1"; else exec tmux attach-session -t "$1"; fi' _ '{{ branch | sanitize }}' '{{ worktree_path }}'
        '';
      };
      ghclone = {
        description = "Clone a GitHub repo to ~/dev and open a session";
        body = ''
          if test (count $argv) -eq 0
            echo "Usage: ghclone org/repo [directory-name]"
            return 1
          end

          set slug $argv[1]

          # If slug doesn't contain "/", prepend cultureamp org
          if not string match -q "*/*" $slug
            set slug "cultureamp/$slug"
          end

          if test (count $argv) -ge 2
            set repo_name $argv[2]
          else
            set repo_name (basename $slug)
          end

          set dev_path ~/dev/$repo_name

          if not test -d $dev_path
            git clone https://github.com/$slug $dev_path >/dev/null 2>&1
            if test $status -ne 0
              echo "Failed to clone repository"
              return 1
            end
          end

          sesh connect $dev_path
        '';
      };
      bkw = {
        description = "Watch Buildkite builds for the current repo and branch";
        body = ''
          set repo (basename (git remote get-url origin) .git)
          set branch (git branch --show-current)

          bk build watch --pipeline $repo --branch $branch $argv
        '';
      };
      bkr = {
        description = "Trigger a new Buildkite build for the current repo and branch";
        body = ''
          set repo (basename (git remote get-url origin) .git)
          set branch (git branch --show-current)

          bk build create --yes --pipeline $repo --branch $branch $argv
        '';
      };
      bko = {
        description = "Open the most recent Buildkite build for the current repo and branch in the browser";
        body = ''
          set repo (basename (git remote get-url origin) .git)
          set branch (git branch --show-current)

          bk build view --pipeline $repo --branch $branch --web $argv
        '';
      };
      bkl = {
        description = "Login to Buildkite CLI with culture-amp org";
        body = ''
          bk auth login --org culture-amp --token $BUILDKITE_API_KEY
        '';
      };
      assume = {
        description = "Select and assume AWS roles using fzf";
        body = ''
          # Find the granted assume.fish script
          set assume_script (readlink -f (which assume) | sed 's|/bin/assume|/share/assume.fish|')

          # Get all profiles from config
          set all_profiles (grep '^\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/\1/' | sort)

          set result (
            printf '%s\n' $all_profiles \
            | fzf --prompt="AWS Profile > " \
                  --preview="grep -A 10 '^\[profile {}\]' ~/.aws/config | grep granted_sso_account_id | head -1 | awk '{print \$NF}'" \
                  --preview-label="Account ID" \
                  --preview-window=down:1:wrap \
                  --bind="ctrl-c:abort" \
                  --expect="ctrl-o" \
                  --header="Enter: assume | Ctrl-o: assume + open console" \
                  --height=40%
          )

          set key $result[1]
          set profile $result[2]

          if test -n "$profile"
            if test "$key" = "ctrl-o"
              source $assume_script $profile -c
            else
              source $assume_script $profile
            end
          end
        '';
      };
    };

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
