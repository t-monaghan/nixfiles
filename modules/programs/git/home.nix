{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.git.enable {
  programs.difftastic = {
    enable = true;
    git = {
      diffToolMode = true;
      enable = true;
    };
  };

  programs.git = {
    enable = true;
    signing.format = null;
    settings = {
      user.name = "t-monaghan";
      user.email = "tomaghan+git@gmail.com";
      push.autoSetupRemote = true;
      pull.rebase = true;
      init.defaultBranch = "main";
      pager.difftool = true;
    };
    ignores = [".DS_Store"];
  };
}
