# if you're on a fresh machine run `nix run nixpkgs#just`
set unstable
set lists

user := `whoami`

homeMan := if which("home-manager") {
  "home-manager"
} else {
  "nix shell nixpkgs#home-manager --command home-manager"
}

# Apply NixOS by hostname, or standalone Home Manager by username. Not for Dolomite.
switch host="":
  #!/usr/bin/env bash
  set -euo pipefail
  host="{{host}}"
  local_hostname=$(hostname -s)
  if [ "$local_hostname" = dolomite ] || [ "$host" = dolomite ]; then
    echo 'Refusing to switch Dolomite from nixfiles.' >&2
    exit 1
  fi
  if [ -e /etc/NIXOS ]; then
    if [ -z "$host" ]; then
      host=$local_hostname
    fi
    echo "Switch output: sudo journalctl -fu nixfiles-switch.service"
    sudo systemd-run --unit=nixfiles-switch.service --service-type=exec --same-dir \
      --wait --collect --setenv=PATH=/run/current-system/sw/bin --setenv=SUDO_UID \
      /run/current-system/sw/bin/nixos-rebuild switch --flake ".#$host"
  else
    if [ -z "$host" ]; then
      host="{{user}}"
    fi
    {{homeMan}} switch --flake ".#$host"
  fi

news:
  {{homeMan + " news --flake .#" + user}}

# Evaluate a home-manager configuration key for a given host (tom.monaghan1, tmonaghan, dolomite, or craton)
eval host attr:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{host}}" = "dolomite" ] || [ "{{host}}" = "craton" ]; then
    nix eval --json '.#nixosConfigurations.{{host}}.config.home-manager.users.tom.{{attr}}' | jq .
  else
    nix eval --json '.#homeConfigurations."{{host}}".config.{{attr}}' | jq .
  fi

# Evaluate all hosts and run node unit tests
check:
  nix eval --raw '.#homeConfigurations."tom.monaghan1".activationPackage.drvPath' && echo ""
  nix eval --raw '.#homeConfigurations.tmonaghan.activationPackage.drvPath' && echo ""
  nix eval --raw '.#nixosConfigurations.dolomite.config.system.build.toplevel.drvPath' && echo ""
  nix eval --raw '.#nixosConfigurations.craton.config.system.build.toplevel.drvPath' && echo ""
  node --test modules/tools/*.test.mjs

# Show the revision and date of the nixpkgs pin in flake.lock
nixpkgs-pin:
  jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
