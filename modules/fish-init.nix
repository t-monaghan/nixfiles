''
  fish_add_path $HOME/.rd/bin
  set -gx fish_color_autosuggestion brblue
  bind \cx\ce edit_command_buffer

  if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  end
        
  if test -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh
    fenv source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
  end''
