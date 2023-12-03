{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = with pkgs; {
    username = "tmonaghan";
    homeDirectory = "/Users/tmonaghan";
    stateVersion = "23.11";
    packages = [
      nodePackages_latest.bash-language-server
      nodePackages_latest.typescript-language-server
      nil
      act
      asciinema
      nerdfonts
      udev-gothic-nf
      neofetch
      python3
      python311Packages.python-lsp-server
      yarn
      # TODO: add rectangle once dots file is findable
    ];
  };
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bat.enable = true;
  programs.gh = {
    enable = true;
  };
  programs.thefuck.enable = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    themes = {
      tmonaghan = let
        transparent = "none"; 
      in {
        inherits = "everforest_dark";
        "ui.background" = transparent;
        "ui.bufferline.active" = { fg = "#e69875";};
      };
    };
    settings = {
      theme = "tmonaghan"; # This should be tmonaghan for darwin, with transparent bg
      editor = {
        line-number = "relative";
        bufferline = "always";
        true-color = true;
      };      
      editor.statusline = {      
        left = ["spacer" "version-control" "position" "mode" "diagnostics"];
        right = ["workspace-diagnostics" "file-name" "spinner"];
      };
      keys.insert = {
        j.k = "normal_mode";
        C-l = ["goto_line_end" ":append-output echo -n ';'" "normal_mode"];
      };
    };
  };
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    initExtra = "neofetch";
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "thefuck"];
    };
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.tmux = {
    enable = true;
  };
  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    useTheme = "uew";
  };
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
      option_as_alt = "Both";
      decorations = "buttonless";
      opacity = 0.95;
      };
      font.normal = {
        family = "UDEV Gothic NF";
        style = "Regular";
      };
      font.size = 15.0;
      schemes = {
        everforest_dark_medium = "&everforest_dark_medium";
        primary = {
          background = "'#2d353b'";
          foreground = "'#d3c6aa'";
        };
        normal = {
          black   = "'#475258'";
          red     = "'#e67e80'";
          green   = "'#a7c080'";
          yellow  = "'#dbbc7f'";
          blue    = "'#7fbbb3'";
          magenta = "'#d699b6'";
          cyan    = "'#83c092'";
          white   = "'#d3c6aa'";
        };
        bright = {
          black  = "'#475258'";
          red    = "'#e67e80'";
          green  = "'#a7c080'";
          yellow = "'#dbbc7f'";
          blue   = "'#7fbbb3'";
          magenta= "'#d699b6'";
          cyan   = "'#83c092'";
          white  = "'#d3c6aa'";
        };
        colors = "*everforest_dark_medium";
    };
  };
  };
}
