{
  env = {
    metadata.name = "env";
    source = {
      command = "printenv";
      output = "{split:=:1..}";
    };
    preview.command = "echo '{split:=:1..}'";
    ui.preview_panel = {
      size = 20;
      header = "{split:=:0}";
    };
  };

  git-log = {
    metadata = {
      name = "git-log";
      description = "A channel to select from git log entries";
      requirements = ["git"];
    };
    source = {
      command = "git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --color=always";
      output = "{strip_ansi|split: :1}";
      ansi = true;
    };
    preview.command = "git show -p --stat --pretty=fuller --color=always '{strip_ansi|split: :1}' | head -n 1000";
  };

  sesh = {
    metadata = {
      name = "sesh";
      description = "A channel to provide a GUI for tmux session manager 'sesh'";
      requirements = ["sesh" "eza" "zoxide"];
    };
    source = {
      command = ["sesh list"];
      ansi = true;
    };
    ui = {
      layout = "landscape";
    };
    keybindings = {
      enter = "actions:select";
      ctrl-k = "actions:kill";
    };
    actions.select = {
      description = "connect to session";
      command = "sesh connect {}";
      mode = "execute";
    };
    actions.kill = {
      description = "kill tmux session";
      command = "tmux kill-session -t {}";
      # TODO: have this return user to the window - fork doesn't work as expected w/ or w/o && exit
      mode = "execute";
    };
    # check if input is a valid tmux session and tmux preview if so, if not, eza
    preview.command = "eza --all --classify=always --color=always --icons=always --tree --level=2 --sort=created --git {strip_ansi}";
  };
}
