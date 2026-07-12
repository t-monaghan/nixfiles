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
is a full-system NixOS host (`nixosConfigurations`) that runs home-manager as a
NixOS module, so all three share the same shell/CLI config (`modules/shell.nix`).

### Optional private overlay

`dolomite` here is the **generic, public base** and builds standalone. Anything
that shouldn't be public lives in a separate private repo
([`nixfiles-private`](https://github.com/t-monaghan/nixfiles-private)) that
exports `nixosModules.dolomite`. The flake declares an optional `private` input
defaulting to the empty `private-stub/` flake, so:

- Macs and public clones build with no access to the private repo (they get the
  empty stub).
- On the box, `./scripts/switch nixos` overrides `private` to a local checkout
  (`$HOME/nixfiles-private`, or `$NIXFILES_PRIVATE`) when it exists, merging the
  private module into `dolomite`.

The override is a path, so nothing is pinned in either direction — public and
private each update with a plain `git pull`, no `nix flake update` needed.

## Structure

```
flake.nix              # mkHost / mkNixosHost helpers, home + nixos configs
lib/
  mkHost.nix           # home-manager builder
  mkNixosHost.nix      # NixOS system builder (threads flake inputs via specialArgs)
hosts/                 # per-Mac config — imports modules
modules/               # home-manager modules
  default.nix          # imports home.nix and work modules
  home.nix             # Mac packages + program configs (imports shell.nix)
  shell.nix            # shared shell + CLI tooling used by ALL three machines
  configs/             # imported config files (tmux, fish, etc.)
  work/culture-amp/    # work-specific config (optional module)
nixos/                 # dolomite full-system config
  configuration.nix    # dolomite host config (wires in home-manager)
  home.nix             # dolomite's home-manager user config (imports shell.nix)
  hardware-configuration.nix
  neovim.nix           # system-wide nixvim
  lib/colours.nix      # shared colour palette
  modules/             # home-assistant + neovim modules
private-stub/          # empty default for the optional `private` overlay input
scripts/switch         # build + switch a config ({nixos|work|personal})
```

The Mac configuration is consolidated in `modules/home.nix`, with extracted
config details in `modules/configs/` imported as needed. The shell + CLI tooling
lives in `modules/shell.nix`, shared by the Macs and the NixOS box alike (Mac-only
bits are guarded by `pkgs.stdenv.isDarwin`). Work-specific modules remain optional
and can be enabled per-host.

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup.
