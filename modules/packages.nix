{ aerospace, pkgs }:
with pkgs;
[
  aerospace.packages.aarch64-darwin.default
  nodePackages_latest.bash-language-server
  nodePackages_latest.typescript-language-server
  nodePackages_latest.vscode-langservers-extracted
  nil
  act
  asciinema
  udev-gothic-nf
  python3
  python311Packages.python-lsp-server
  tree
  yaml-language-server
  shellcheck
  jdk11
  taplo
  killport
  trash-cli
  fzf
  _1password
  nixpkgs-fmt
  lnav
  lazygit
  toml2json
  marksman
  difftastic
  # TODO: add rectangle once dots file is findable
]