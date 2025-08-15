{pkgs}: {
  enable = true;

  loginShellInit = import ./fish-init.nix;

  shellAbbrs = {
    nv = "nvim";
    mx = "tmuxinator";
    ci = "gh altar ci > /dev/null 2>&1 & disown";
    dismiss = "curl 'http://192.168.1.97/api/notify/dismiss'";
    stats = "curl 'http://192.168.1.97/api/stats' | jq";

    chmox = "chmod a+x";

    gco = "git checkout";
    gp = "git push";
    gpu = "git pull --autostash --rebase";
    gs = "git status";
    gl = "git log --compact-summary --oneline";
    gd = "git difftool";
    gdc = "git difftool --cached";
    ga = "git add";
    gc = "git commit -m";
    ghpr = "gh pr checkout";
    gsc = "git stash clear";
    gsa = "git stash apply";
    gcob = "git checkout -b";

    ll = "ls -ltra";

    dr = "devbox run";
    drs = "devbox run setup";
    drp = "devbox run populate";
    dsu = "devbox services up --pcflags '--keep-project'";
    reload = "rm -rf .devbox && direnv reload";
    hs = "hotel services";
    rmd = "rm -rf .devbox";

    zed = "open -a 'Zed Preview' . && exit";
    rt = "trash-put";
    hlogs = "tail -f ~/.local/share/hotel/log.jsonl | fblog -m event";
    disu = "caffeinate -disu";
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
    gw = {
      wraps = ''gradle'';
      body = ''./gradlew $argv'';
    };
  };

  plugins = [
    {inherit (pkgs.fishPlugins.foreign-env) name src;}
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
