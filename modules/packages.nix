{pkgs}:
with pkgs; [
  udev-gothic-nf # great font
  # cli tools
  tree
  killport
  fzf
  fblog
  hyperfine
  difftastic
  # linters
  golangci-lint
  shellcheck
  # formatters
  stylua
  nixpkgs-fmt
  alejandra
  # lsps
  gopls
  nil
  gopls
  taplo
  nixd
  marksman
  yaml-language-server
  lua-language-server
  nodePackages_latest.bash-language-server
  nodePackages_latest.typescript-language-server
  nodePackages_latest.vscode-langservers-extracted
  nodePackages_latest.prettier
  kotlin-language-server
]
