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
    prettierd
    python313
    python313Packages.python-lsp-ruff
    python313Packages.pyls-isort
    python313Packages.black
  ];
}
