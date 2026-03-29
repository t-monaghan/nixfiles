{config, lib, pkgs, ...}:
lib.mkIf config.nixfiles.development.enable {
  programs.go.enable = true;
  programs.gemini-cli.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    eza
    pnpm
    just
    terminal-notifier
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
    python313
    python313Packages.python-lsp-server
    python313Packages.python-lsp-ruff
    python313Packages.jedi-language-server
    python313Packages.pyls-isort
    python313Packages.black
    pyright
    basedpyright
    tflint
    terraform-ls
  ];
}
