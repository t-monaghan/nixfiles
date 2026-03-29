# Nixfiles

Standalone home-manager configurations for my machines, using a unified module pattern.

## Hosts

| Config | Machine | Switch command |
|---|---|---|
| `personal` | Personal macbook | `home-manager switch --flake .#personal` |
| `work` | Culture Amp macbook | `home-manager switch --flake .#work` |

## Structure

```
flake.nix              # mkHost helper, two homeConfigurations
hosts/                 # per-machine config — enables modules
modules/
  default.nix          # auto-imports all common.nix + home.nix recursively
  development/         # dev tools, languages, LSPs
  programs/            # one dir per program (common.nix + home.nix)
    defaultCli/        # meta-module that enables all CLI tools
    defaultGui/        # meta-module that enables all GUI programs
    ...
  work/culture-amp/    # work-specific config
scripts/               # convenience wrappers for home-manager
```

Each module follows the convention:
- `common.nix` declares `options.nixfiles.<path>.enable`
- `home.nix` implements the config, gated by `lib.mkIf`

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup, and
[Jadarma's unified modules post](https://jadarma.github.io/blog/posts/2026/03/unified-modules-for-your-nixfiles/) for the module pattern.
