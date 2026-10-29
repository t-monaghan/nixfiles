# nixfiles

This is the user's NixOS/Home Manager configuration repository. It manages most user-level tooling configuration, including pi's own config (`modules/tools/pi-coding-agent/`), Claude Code config, and other dotfiles.

## Organization

- `hosts/`: Host entry points (`tom.monaghan1.nix`, `tmonaghan.nix`, `dolomite/`). Each host sets `nixfiles.context` (`host`, `platform`, `role.{desktop,work,homelab}`, `flakePath`).
- `modules/context.nix`: Schema for `nixfiles.context`.
- `modules/theme/`: Shared base16 palettes (`colours.nix`) and font settings (`fonts.nix`).
- `modules/tools/`: Self-contained per-tool modules. Every configuration key for a given tool across all environments lives in its `modules/tools/<tool>` module.
- Use `just eval <host> <attr>` to inspect the resolved value of any option for a given host.

When making changes to tool configurations, dotfiles, or agent settings, they belong in this repo — not directly in `~/.pi/agent/` or similar paths.
