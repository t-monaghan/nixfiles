{inputs, ...}: {
  imports = [
    inputs.nixvim.nixosModules.nixvim
    # `colors` + `fonts` as module arguments, shared with the Macs.
    ../modules/args.nix
    # The same nixvim configuration the Macs use.
    ../modules/configs/neovim
  ];

  # nixd's flake-based expressions are Mac-only (see
  # ../modules/configs/neovim/lsp.nix); on this box nixd resolves nixpkgs and
  # the NixOS options through the channel instead, which is what null selects.
  _module.args = {
    flakePath = null;
    homeConfigName = null;
  };
}
