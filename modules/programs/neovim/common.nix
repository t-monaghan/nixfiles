{lib, ...}: {
  options.nixfiles.programs.neovim.enable = lib.mkEnableOption "neovim";
}
