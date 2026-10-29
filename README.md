# Nixfiles

Public home-manager configurations for my Macs and the public NixOS base for my
home server, `dolomite`.

## Hosts

| Config | Machine | Command |
|---|---|---|
| `tmonaghan` | Personal MacBook | `just switch` |
| `tom.monaghan1` | Culture Amp MacBook | `just switch` |
| `dolomite` | Public NixOS base | `nix build .#nixosConfigurations.dolomite.config.system.build.toplevel` |

`tmonaghan` and `tom.monaghan1` are home-manager configurations. The public
`dolomite` configuration is also exported so it can be evaluated and built
without any private inputs or stubs.

The flake exposes `lib.mkDolomite { extraModules = [ ... ]; }` as the supported
composition interface. The private
[`nixfiles-private`](https://github.com/t-monaghan/nixfiles-private) repository
pins this flake and uses that function to add private services. It is the
Dolomite deployment entry point; this public repository does not depend on or
look for it.

## Common commands

```sh
# Evaluate all three hosts and run unit tests
just check

# Inspect a resolved home-manager option for a host
just eval tom.monaghan1 programs.fish.shellAbbrs

# Update public inputs
nix flake update

# Switch the current Mac configuration
just switch
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
  overlays.nix         # shared nixpkgs overlays
hosts/
  tmonaghan.nix        # personal Mac configuration
  tom.monaghan1.nix    # work Mac configuration
  dolomite/            # public Dolomite NixOS + home-manager configuration
modules/
  context.nix          # nixfiles.context schema (host, role, flakePath)
  home.nix             # root home-manager module imported by all hosts
  shell.nix            # shared shell and CLI baseline
  theme/               # shared base16 palettes and font settings
  tools/               # self-contained per-tool modules
```

All three hosts import `modules/home.nix`. Tool modules adapt via
`nixfiles.context` (`role.desktop`, `role.work`, `role.homelab`) and
`pkgs.stdenv.hostPlatform.isDarwin`.

## Credits

Thanks to [Jack Rose](https://github.com/jay-aye-see-kay/nixfiles) for the initial setup.
