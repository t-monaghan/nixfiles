{
  "$schema" = "https://starship.rs/config-schema.json";
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
  character = {
    error_symbol = "[❯](red)";
    success_symbol = "[❯](bold cyan)";
    vimcmd_symbol = "[ ](green)";
    vimcmd_visual_symbol = "[ ](yellow)";
  };
  custom = {
    devbox = {
      command = "command_output=$(devbox version 2>&1)\nversion=$(echo \"$command_output\" | grep -E '^[0-9]+(\\.[0-9]+){2}$')\nif echo \"$command_output\" | grep -q \"Info: New devbox available:\"; then \n  update_version=$(echo \"$command_output\" | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' | sed -n '2p')\n  echo \"$version update available ($update_version)\" \nelse\n  echo \"$version\"\nfi\n";
      description = "Shows the devbox version if inside a devbox project";
      format = "[$symbol v($output )]($style)";
      shell = "/bin/bash";
      style = "bold blue";
      symbol = " ";
      when = "[[ -n $DEVBOX_INIT_PATH ]]\n";
    };
    direnv = {
      command = "if [[ -f ./devbox.json ]]; then\n  direnv_output=$(direnv status)\n  ## Confusingly, direnv has a status of 0 for allowed\n  if echo $direnv_output | grep -q \"Found RC allowed 0\"; then\n    echo \"\"\n  else\n    echo \" direnv is not allowed\"\n  fi\nfi\n";
      description = "Shows if direnv has not been allowed if inside a project with a .envrc and devbox.json";
      shell = "sh";
      when = "[[ -n $DIRENV_FILE ]]\n";
    };
  };
  directory = {style = "bold cyan";};
  format = "$directory$git_branch$git_status$git_state$direnv$java$golang$ruby$node$custom\n$status$character";
  git_branch = {
    style = "yellow";
    symbol = " ";
  };
  git_status = {
    deleted = " ";
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
    symbol = " ";
  };
  nix_shell = {
    disabled = false;
    format = "[$symbol$state( \\($name\\))]($style) ";
    symbol = "󰜗 ";
  };
  right_format = "$memory_usage$battery";
  ruby = {
    format = "[$symbol($version )]($style)";
    symbol = " ";
  };
  status = {
    disabled = false;
    format = "[$status]($style)";
  };
  time = {disabled = false;};
}
