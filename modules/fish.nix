{ pkgs }:
{
  enable = true;

  loginShellInit = import ./fish-init.nix;

  shellAbbrs = {
    chmox = "chmod a+x";

    gco = "git checkout";
    gp = "git push";
    gpu = "git pull";
    gs = "git status";
    gl = "git log --compact-summary --oneline";
    gd = "git difftool";
    gdc = "git difftool --cached";
    ga = "git add";
    gc = "git commit -m";
    gpr = "gh pr view --web";


    ll = "ls -l --time-style relative";

    dr = "devbox run";
    drs = "devbox run setup";
    drp = "devbox run populate";
    dsu = "devbox services up --pcflags '--keep-tui'";
    hs = "hotel services";
    rmd = "rm -rf .devbox";

    zed = "open -a 'Zed Preview' . && exit";
    rt = "trash-put";
    hlogs = "tail -f ~/.local/share/hotel/log.jsonl | fblog -m event";
  };

  shellAliases = {
    assume = "source /usr/local/bin/assume.fish";
  };

  functions = {
    fish_greeting = {
      body = '''';
    };
    starship_transient_rprompt_func = {
      body = ''starship module time'';
    };
  };

  plugins = [
    { inherit (pkgs.fishPlugins.foreign-env) name src; }
    {
      name = "pnpm-shell-completion";
      src = pkgs.fetchFromGitHub {
        owner = "g-plane";
        repo = "pnpm-shell-completion";
        rev = "v0.5.2";
        sha256 = "sha256-VCIT1HobLXWRe3yK2F3NPIuWkyCgckytLPi6yQEsSIE=";
      };
    }
  ];

}
