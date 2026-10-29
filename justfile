# if you're on a fresh machine run `nix run nixpkgs#just`
set unstable
set lists

user := `whoami`

homeMan := if which("home-manager") == "" {
  "nix shell nixpkgs#home-manager --command home-manager"
} else {
  "home-manager"
}

switch:
  {{homeMan + " switch --flake .#" + user}}

news:
  {{homeMan + " news --flake .#" + user}}

# Evaluate a home-manager configuration key for a given host (tom.monaghan1, tmonaghan, or dolomite)
eval host attr:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{host}}" = "dolomite" ]; then
    nix eval --json '.#nixosConfigurations.dolomite.config.home-manager.users.tom.{{attr}}' | jq .
  else
    nix eval --json '.#homeConfigurations."{{host}}".config.{{attr}}' | jq .
  fi

# Evaluate all three hosts and run node unit tests
check:
  nix eval --raw '.#homeConfigurations."tom.monaghan1".activationPackage.drvPath' && echo ""
  nix eval --raw '.#homeConfigurations.tmonaghan.activationPackage.drvPath' && echo ""
  nix eval --raw '.#nixosConfigurations.dolomite.config.system.build.toplevel.drvPath' && echo ""
  node --test modules/tools/*.test.mjs

# Show the revision and date of the nixpkgs pin in flake.lock
nixpkgs-pin:
  jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
