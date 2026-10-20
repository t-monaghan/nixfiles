{
  config,
  lib,
}: {
  recipe =
    {
      pi-sessions = {
        command = "pi-hud list";
        columns = ["state" "repository" "session" "worktree" "updated"];
        colors.state = {
          Waiting = "yellow";
          Working = "green";
          Idle = "cyan";
          Background = "blue";
          Saved = "gray";
          "Missing directory" = "red";
          completed = "green";
          failed = "red";
          canceled = "gray";
        };
        keys.enter = {run = ["pi-hud" "connect" "{{.key}}"];};
        refresh = 5;
      };
      pull-requests = {
        command = ''gh search prs --author @me --limit 100 --state open --json repository,number,isDraft,state,title,url | jq 'map(.repository = .repository.name)' '';
        columns = ["repository" "number" "title" "state" "isDraft"];
        keys = {
          enter = {run = ["open" "{{.url}}"];};
        };
        refresh = 60;
      };
      tmux-windows = {
        command = ''
          tmux list-windows -a -F '#{session_name}::#{pane_title}::#{window_id}::#{window_name}' |
            jq -Rn '[inputs | capture("^(?<session_name>.*?)::(?<pane_title>.*)::(?<window_id>.*)::(?<window_name>.*)$")]'
        '';
        columns = ["session_name" "pane_title"];
        keys = {
          enter = {run = ["sesh" "window" "connect" "-t" "{{.session_name}}" "{{.window_name}}"];};
          "ctrl+d" = {run = ["tmux" "kill-window" "-t" "{{.window_id}}"];};
        };
        refresh = 3;
      };
    }
    // lib.optionalAttrs config.nixfiles.work.cultureAmp.enable {
      builds = {
        command = ''
          bk build list --no-input --no-pager --quiet \
            --creator=019cf524-0afa-49e6-8e3c-52ce91377aa7 \
            --limit 50 --json |
            jq '[.[] | {
              "repo/project": (.pipeline.slug // "—"),
              status: .state,
              branch: .branch,
              "commit message": ((.message // "") | split("\n")[0]),
              url: .web_url
            }]'
        '';
        columns = ["repo/project" "status" "branch" "commit message"];
        colors.status = {
          passed = "green";
          running = "blue";
          scheduled = "yellow";
          blocked = "yellow";
          canceling = "yellow";
          failed = "red";
          canceled = "gray";
          skipped = "gray";
          not_run = "gray";
        };
        refresh = 30;
        keys.enter = {run = ["open" "{{.url}}"];};
      };
    };
  page = [
    {
      title = "Main";
      sections =
        [
          {
            title = "Pi sessions";
            recipe = "pi-sessions";
          }
          {
            title = "Windows";
            recipe = "tmux-windows";
          }
          {
            title = "Pull Requests";
            recipe = "pull-requests";
          }
        ]
        ++ lib.optionals config.nixfiles.work.cultureAmp.enable [
          {
            title = "Buildkite builds";
            recipe = "builds";
          }
        ];
    }
  ];
}
