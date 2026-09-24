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

# Show the revision and date of the nixpkgs pin in flake.lock
nixpkgs-pin:
  jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
