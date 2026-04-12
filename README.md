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
hosts/                 # per-machine config — imports modules
modules/
  default.nix          # imports home.nix and work modules
  home.nix             # all packages and program configs
  configs/             # imported config files (tmux, fish, etc.)
  work/culture-amp/    # work-specific config (optional module)
scripts/               # convenience wrappers for home-manager
```

The configuration is consolidated in `modules/home.nix`, with extracted config details in `modules/configs/` imported as needed. Work-specific modules remain optional and can be enabled per-host.

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup.
