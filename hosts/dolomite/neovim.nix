{inputs, ...}: {
  imports = [
    inputs.nixvim.nixosModules.nixvim
    # `colors` + `fonts` as module arguments, shared with the Macs.
    ../../modules/theme
    # The same nixvim configuration the Macs use.
    ../../modules/tools/neovim
  ];
}
