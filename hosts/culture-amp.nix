{ pkgs, ...}:
{
  home = with pkgs; {
    username = "tom.monaghan";
    homeDirectory = "/Users/tom.monaghan";
    packages = [
      nodejs_18
      nodePackages.pnpm
      rtx
      yarn
      rubyPackages_3_2.solargraph
      ];
    };
  programs.zsh.initExtra = ''
                            fastfetch
                            export DIRENV_BIN="/Users/tom.monaghan/.nix-profile/bin/direnv"
                            eval "$($DIRENV_BIN hook zsh)"
                            export NIX_SSL_CERT_FILE='/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem'
                            fpath+=(/Users/tom.monaghan/.nix-profile/share/zsh/site-functions)
                            eval "$(rtx activate zsh)"
                            # Below is the install for a better zsh vi mode
                            source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
                            '';
}
