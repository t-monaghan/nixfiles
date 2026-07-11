# Nixfiles

Standalone home-manager configurations for my Macs plus the full-system NixOS
config for my home server, `dolomite`, using a unified module pattern.

## Hosts

| Config | Machine | Switch command |
|---|---|---|
| `personal` | Personal macbook | `./scripts/switch personal` |
| `work` | Culture Amp macbook | `./scripts/switch work` |
| `dolomite` | NixOS home server | `./scripts/switch nixos` |

`personal` / `work` are home-manager configs (`homeConfigurations`); `dolomite`
is a full-system NixOS host (`nixosConfigurations`).

> The `dolomite` config here is the **generic, public base**. The box itself
> builds `.#dolomite` from a private overlay repo that layers additional,
> non-public config on top of this via `extendModules`.

## Structure

```
flake.nix              # mkHost / mkNixosHost helpers, home + nixos configs
lib/
  mkHost.nix           # home-manager builder
  mkNixosHost.nix      # NixOS system builder (threads flake inputs via specialArgs)
hosts/                 # per-Mac config — imports modules
modules/               # home-manager modules
  default.nix          # imports home.nix and work modules
  home.nix             # all packages and program configs
  configs/             # imported config files (tmux, fish, etc.)
  work/culture-amp/    # work-specific config (optional module)
nixos/                 # dolomite full-system config
  configuration.nix    # dolomite host config
  hardware-configuration.nix
  neovim.nix           # system-wide nixvim
  shell.nix            # fish + CLI tooling (imported when ready)
  lib/colours.nix      # shared colour palette
  modules/             # home-assistant + neovim modules
scripts/switch         # build + switch a config ({nixos|work|personal})
```

The Mac configuration is consolidated in `modules/home.nix`, with extracted
config details in `modules/configs/` imported as needed. Work-specific modules
remain optional and can be enabled per-host.

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup.
