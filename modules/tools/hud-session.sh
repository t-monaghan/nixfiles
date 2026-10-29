# sesh starts commands in a detached 80x24 session, before the client sets its size.
if [ -n "${TMUX_PANE:-}" ]; then
  while [ "$(tmux display-message -p -t "$TMUX_PANE" '#{session_attached}')" = 0 ]; do
    sleep 0.05
  done
fi

exec hud "$@"
