# Shared theme data, handed to every module as a module argument.
#
# `colors` (./colours.nix) and `fonts` (./fonts.nix) are plain data: no
# options, no host differences, no dependency on `pkgs`. Setting them in
# `_module.args` here means any module in the evaluation can take `colors` or
# `fonts` in its argument set — the same way it takes `pkgs` or `lib`.
{...}: {
  _module.args = {
    colors = import ./colours.nix;
    fonts = import ./fonts.nix;
  };
}
