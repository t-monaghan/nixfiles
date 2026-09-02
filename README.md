# Nixfiles

Public home-manager configurations for my Macs and the public NixOS base for my
home server, `dolomite`.

## Hosts

| Config | Machine | Command |
|---|---|---|
| `personal` | Personal MacBook | `./scripts/switch personal` |
| `work` | Culture Amp MacBook | `./scripts/switch work` |
| `dolomite` | Public NixOS base | `nix build .#nixosConfigurations.dolomite.config.system.build.toplevel` |

`personal` and `work` are home-manager configurations. The public `dolomite`
configuration is also exported so it can be evaluated and built without any
private inputs or stubs.

The flake exposes `lib.mkDolomite { extraModules = [ ... ]; }` as the supported
composition interface. The private
[`nixfiles-private`](https://github.com/t-monaghan/nixfiles-private) repository
pins this flake and uses that function to add private services. It is the
Dolomite deployment entry point; this public repository does not depend on or
look for it.

## Common commands

```sh
# Check every public output and evaluate the public Dolomite base
nix flake check
nix eval .#nixosConfigurations.dolomite.config.system.build.toplevel.drvPath

# Update public inputs
nix flake update

# Switch a Mac configuration
./scripts/switch personal
./scripts/switch work
```

Builds and switches of the complete Dolomite configuration are run from
`nixfiles-private`. See that repository's README for its pinned update and local
override workflows.

## Structure

```
flake.nix              # public outputs and lib.mkDolomite
lib/
  mkHost.nix           # home-manager builder
  mkNixosHost.nix      # NixOS builder
hosts/                 # per-Mac configuration
modules/               # shared home-manager modules and program configuration
nixos/                 # public Dolomite system configuration
scripts/switch         # switch personal or work home-manager configuration
```

The shared shell and CLI configuration lives in `modules/shell.nix` and is used
by the Macs and Dolomite. Mac-only settings are guarded by
`pkgs.stdenv.isDarwin`.

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup.
