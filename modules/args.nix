# Shared data, handed to every module as a module argument.
#
# `colors` (./configs/colours.nix) and `fonts` (./configs/fonts.nix) are plain
# data: no options, no host differences, no dependency on `pkgs`. Setting them
# in `_module.args` here means any module in the evaluation can take `colors` or
# `fonts` in its argument set — the same way it takes `pkgs` or `lib` — instead
# of each file `import`ing them again.
#
# `_module.args` exists in both module systems, so this file is imported by the
# home-manager entry points (./home.nix, ./shell.nix) and by the NixOS
# evaluation (../nixos/neovim.nix). Importing the same path twice is
# deduplicated by the module system, so listing it in several entry points is
# safe.
{...}: {
  _module.args = {
    colors = import ./configs/colours.nix;
    fonts = import ./configs/fonts.nix;
  };
}
