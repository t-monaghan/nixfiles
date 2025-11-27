{pkgs}:
with pkgs; [
  google-cloud-sdk
  docker
  tfswitch
  nodejs_22
  nerd-fonts.jetbrains-mono
  jetbrains-mono
  eza
  pnpm
  just
  postgresql
  # cli tools
  tree
  killport
  fblog
  hyperfine
  watchexec
  # linters
  golangci-lint
  shellcheck
  # formatters
  stylua
  nixpkgs-fmt
  alejandra
  ruff
  # lsps
  gopls
  nil
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
  python313
  python313Packages.python-lsp-server
  python313Packages.python-lsp-ruff
  python313Packages.jedi-language-server
  python313Packages.jedi-language-server
  python313Packages.pyls-isort
  python313Packages.black
  pyright
  basedpyright
  tflint
  terraform-ls
]
