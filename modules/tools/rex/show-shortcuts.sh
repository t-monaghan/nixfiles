rows=$(rex --autostart=false keymap --json | jq -r -f "$REX_SHORTCUT_ROWS")

status=0
printf '%s\n' "$rows" |
  FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf \
    --layout=reverse --no-sort --border \
    --header='Configured Rex bindings · Esc closes' \
    --prompt='Search bindings> ' \
    --bind='esc:abort,enter:ignore' >/dev/null || status=$?

case "$status" in
  0|1|130) exit 0 ;;
  *) exit "$status" ;;
esac
