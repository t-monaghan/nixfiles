{
  nix-search-tv = {
    metadata.name = "nix-search-tv";
    # nix-search-tv only looks for config at XDG_CONFIG_HOME which is unset in my environment
    source.command = "XDG_CONFIG_HOME=$HOME/.config nix-search-tv print";
    preview.command = "XDG_CONFIG_HOME=$HOME/.config nix-search-tv preview {}";
    actions = {
      open-source.command = "open $(nix-search-tv source {})";
      open-homepage.command = "open $(nix-search-tv homepage {})";
    };
    keybindings = {
      enter = "actions:open-source";
      ctrl-h = "actions:open-homepage";
    };
  };

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
}
