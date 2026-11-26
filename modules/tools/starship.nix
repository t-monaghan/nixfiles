{
  config,
  lib,
  ...
}: let
  showHostname = config.nixfiles.context.role.homelab;
in {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      direnv.disabled = false;
      battery = {
        charging_symbol = "󰚥";
        display = [
          {
            discharging_symbol = "󱊣";
            style = "green";
            threshold = 100;
          }
          {
            style = "green";
            threshold = 75;
          }
          {
            discharging_symbol = "󱊢";
            style = "yellow";
            threshold = 50;
          }
          {
            discharging_symbol = "󱊡";
            style = "yellow";
            threshold = 20;
          }
          {
            discharging_symbol = "󰂃";
            style = "red";
            threshold = 0;
          }
        ];
        format = "[$symbol $percentage]($style) ";
        full_symbol = "󱊣";
        unknown_symbol = "󱈑";
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
          style = "bold blue";
          when = "[[ -n $AWS_PROFILE ]]";
        };
        devbox = {
          command = "command_output=$(devbox version 2>&1)\nversion=$(echo \"$command_output\" | grep -E '^[0-9]+(\\.[0-9]+){2}$')\nif echo \"$command_output\" | grep -q \"Info: New devbox available:\"; then \n  update_version=$(echo \"$command_output\" | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' | sed -n '2p')\n  echo \"$version update available ($update_version)\" \nelse\n  echo \"$version\"\nfi\n";
          description = "Shows the devbox version if inside a devbox project";
          format = "[$symbol($output )]($style)";
          shell = "/bin/bash";
          style = "bold blue";
          symbol = " ";
          when = "[[ -n $DEVBOX_INIT_PATH ]]\n";
        };
      };
      directory = {style = "bold cyan";};
      format = "${lib.optionalString showHostname "$hostname"}$directory$git_branch$git_status$git_state$direnv$java$golang$ruby$node$custom\n$status$character";
      hostname = lib.mkIf showHostname {
        ssh_only = false;
      };
      git_branch = {
        style = "yellow";
        symbol = " ";
      };
      git_status = {
        deleted = " ";
        format = "([$all_status$ahead_behind]($style))";
        modified = "󰏫 ($count) ";
        staged = "󰶍 ";
        stashed = "󰴮 ";
        style = "yellow";
        untracked = "󰊇 ($count) ";
      };
      golang = {
        style = "bold green";
        symbol = "󰟓 ";
      };
      java = {
        format = "[$symbol($version )]($style)";
        symbol = " ";
      };
      nix_shell = {
        disabled = false;
        format = "[$symbol$state( \\($name\\))]($style) ";
        symbol = "󰜗 ";
      };
      right_format = "$memory_usage$battery";
      ruby = {
        format = "[$symbol($version )]($style)";
        symbol = " ";
      };
      status = {
        disabled = false;
        format = "[$status]($style)";
      };
      time = {disabled = false;};
    };
  };
}
