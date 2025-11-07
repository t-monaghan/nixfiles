{lib, ...}: let
  taps = [
  ];

  brews = [
    "ffmpeg"
    "libmagic"
    "weasyprint"
    "glib"
    "redis"
    "pango"
    "gdk-pixbuf"
    "librsvg"
    "cairo"
  ];

  casks = [
  ];
in
  with lib; {
    home.sessionPath = ["/opt/homebrew/bin"];

    home.file.".Brewfile" = {
      text =
        (concatMapStrings (
            tap:
              ''tap "''
              + tap
              + ''
                "
              ''
          )
          taps)
        + (concatMapStrings (
            brew:
              ''brew "''
              + brew
              + ''
                "
              ''
          )
          brews)
        + (concatMapStrings (
            cask:
              ''cask "''
              + cask
              + ''
                "
              ''
          )
          casks);
      onChange = ''
        /opt/homebrew/bin/brew bundle install --cleanup --no-upgrade --force --global
      '';
    };
  }
