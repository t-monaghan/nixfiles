{ ...}:
{
  home = {
    username = "tom.monaghan";
    homeDirectory = "/Users/tom.monaghan";
};
    programs.zsh.initExtra = ''
                              fastfetch
                              export DIRENV_BIN="/Users/tom.monaghan/.nix-profile/bin/direnv"
                              eval "$($DIRENV_BIN hook zsh)"
                              export NIX_SSL_CERT_FILE='/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem'
                              fpath+=(/Users/tom.monaghan/.nix-profile/share/zsh/site-functions)'';
}
