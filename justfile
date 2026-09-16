# Show the revision and date of the nixpkgs pin in flake.lock.
nixpkgs-pin:
    #!/usr/bin/env bash
    set -euo pipefail
    jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
