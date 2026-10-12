{
  config,
  lib,
}: {
  recipe =
    {
      pi-sessions = {
        command = "pi-hud list";
        columns = ["state" "repository" "session" "worktree" "updated"];
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
            --state=running --no-limit --json |
            jq '[.[] as $build | $build.jobs[]?
              | select(.state == "running")
              | {
                  pipeline: $build.pipeline.slug,
                  branch: $build.branch,
                  build: $build.number,
                  job: (.name // .label),
                  url: .web_url
                }]'
        '';
        columns = ["pipeline" "branch" "build" "job"];
        refresh = 10;
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
            title = "Running jobs";
            recipe = "builds";
          }
        ];
    }
  ];
}
