[working-directory: '.']
switch:
  #!/usr/bin/env bash
  set -euo pipefail
  user=$(whoami)
  if command -v home-manager &>/dev/null; then
    home-manager switch --flake ".#$user"
  else
    nix shell nixpkgs#home-manager --command home-manager switch --flake ".#$user"
  fi

news host:
  nix run home-manager -- news --flake .#{{host}}

# Show the revision and date of the nixpkgs pin in flake.lock
nixpkgs-pin:
  jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
