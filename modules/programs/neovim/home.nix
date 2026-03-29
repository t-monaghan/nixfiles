{config, lib, pkgs, ...}:
lib.mkIf config.nixfiles.programs.neovim.enable {
  home.packages = [pkgs.neovim];

  home.sessionVariables.EDITOR = "nvim";

  # Symlink mutable neovim config (git submodule)
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/module-refactor/modules/programs/neovim/kickstart.nvim";
}
