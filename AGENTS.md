# nixfiles

This is the user's NixOS/nix-darwin configuration repository. It manages most user-level tooling configuration, including pi's own config (`modules/configs/pi-coding-agent/`), Claude Code config, and other dotfiles.

When making changes to tool configurations, dotfiles, or agent settings, they likely belong in this repo — not directly in `~/.pi/agent/` or similar paths.
