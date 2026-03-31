# Meta-module: enables all default CLI tools.
{
  config,
  lib,
  ...
}:
lib.mkIf config.nixfiles.programs.defaultCli.enable {
  nixfiles.programs = {
    fish.enable = true;
    git.enable = true;
    bat.enable = true;
    starship.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    atuin.enable = true;
    direnv.enable = true;
    tmux.enable = true;
    neovim.enable = true;
    sesh.enable = true;
    television.enable = true;
    nix-search-tv.enable = true;
    claude-code.enable = true;
    opencode.enable = true;
    gh.enable = true;
    navi.enable = true;
  };

  programs.ripgrep.enable = true;
  programs.fd.enable = true;
}
