{
  blacklist = ["/dev"];
  session = [
    {
      name = "hotel";
      path = "~/dev/hotel/";
      preview_command = "eza --all --git --ignore-glob='.git|.devbox' --icons --tree --level=2 --color=always --sort=time --reverse {}";
    }
    {
      name = "sesh-config";
      path = "~/dev/nixfiles";
      startup_command = "nvim dots/sesh.toml";
    }
  ];
}
