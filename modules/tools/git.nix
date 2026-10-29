{...}: {
  programs = {
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = {
        color_labels = true;
      };
    };

    difftastic = {
      enable = true;
      git = {
        mode = "difftool";
        enable = true;
      };
    };

    git = {
      enable = true;
      signing.format = null;
      settings = {
        user.name = "t-monaghan";
        user.email = "tomaghan+git@gmail.com";
        push.autoSetupRemote = true;
        pull.rebase = true;
        init.defaultBranch = "main";
        difftool.prompt = "false";
        pager.difftool = "true";
        rerere.enabled = true;
        branch.sort = "-committerdate";
      };
      # .worktrees/ is where worktrunk (`wt`) creates in-repo worktrees; ignore
      # it everywhere so they never show as untracked / dirty the tree.
      ignores = [".DS_Store" ".worktrees/"];
    };
  };
}
