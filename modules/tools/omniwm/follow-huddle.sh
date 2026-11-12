workspace=$(omniwmctl query active-workspace --json | jq -er '
  select(.ok == true) | .result.payload.workspace.rawName // empty
')
windows=$(omniwmctl query windows --bundle-id com.tinyspeck.slackmacgap --json)
ids=$(jq -er --arg workspace "$workspace" --arg pattern "$HUDDLE_TITLE_REGEX" '
  select(.ok == true) | .result.payload.windows
  | map(select(
      .app.bundleId == "com.tinyspeck.slackmacgap"
      and .mode == "floating"
      and (.isScratchpad | not)
      and (.title | test($pattern))
      and .workspace.rawName != $workspace
    ) | .id)
  | join("\n")
' <<< "$windows")

while IFS= read -r id; do
  [ -n "$id" ] || continue
  omniwmctl window move-to-workspace "$id" "$workspace"
done <<< "$ids"
