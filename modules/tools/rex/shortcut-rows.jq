(.actions // [] | map({key: .name, value: (.title // .name)}) | from_entries) as $titles
| .bindings
| sort_by(.keys)
| .[]
| select(.action != null)
| . as $binding
| [
    (.keys | join(" > ")),
    ($titles[.action] // .action),
    (if .args then (.args | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(" ")) else "" end)
  ]
| join("    ")
