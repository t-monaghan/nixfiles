{
  recipe.sesh-releases = {
    command = "gh release list --repo joshmedeski/sesh --json name,publishedAt";
    columns = ["name" "publishedAt"];
  };
  recipe.windows = {
    command = ''
      tmux list-windows -a -F '#{session_name}::#{pane_title}' |
        jq -Rn '[inputs | capture("^(?<session_name>.*?)::(?<pane_title>.*)$")]'
    '';
    columns = ["pane_title" "session_name"];
  };
  page = [
    {
      title = "Sesh";
      sections = [
        {
          title = "Windows";
          recipe = "windows";
        }
      ];
    }
    # {
    #   title = "GitHub";
    #   sections = [
    #     {
    #       title = "Releases";
    #       recipe = "sesh-releases";
    #     }
    #   ];
    # }
  ];
}
