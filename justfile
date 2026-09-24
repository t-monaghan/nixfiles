set unstable
set lists

homeManPath := which("home-manager")
user := `whoami`
switchCmd := if which("home-manager") == "" {
  "nix shell nixpkgs#home-manager --command home-manager switch --flake .#"
} else {
  "home-manager switch --flake .#"
}

[working-directory: '.']
switch:
  {{switchCmd + user}}

news:
  nix run home-manager -- news --flake .#{{user}}

# Show the revision and date of the nixpkgs pin in flake.lock
nixpkgs-pin:
  jq -r '.nodes.nixpkgs.locked | "rev:  \(.rev)\ndate: \(.lastModified | strftime("%Y-%m-%d"))"' flake.lock
