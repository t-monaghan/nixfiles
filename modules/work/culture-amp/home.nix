{config, lib, pkgs, ...}:
lib.mkIf config.nixfiles.work.cultureAmp.enable {
  programs.fish = {
    interactiveShellInit = "set -gx _ZO_EXCLUDE_DIRS $HOME/hotel";
    shellAbbrs = {
      "hsu" = "hotel services up";
      "hsl" = "hotel services logs --follow --all";
      "hsd" = "hotel services down";
      "hsls" = "hotel services list";
    };
    functions = {
      clone = {
        description = "Clone a cultureamp repo";
        body = ''
          if set -q argv[2]
              git clone https://github.com/cultureamp/"$argv[1]" "$argv[2..-1]"
          else
              git clone https://github.com/cultureamp/"$argv[1]"
              cd "$argv[1]"
          end
        '';
      };
    };
  };

  programs.awscli.enable = true;
  programs.mise.enable = true;
}
