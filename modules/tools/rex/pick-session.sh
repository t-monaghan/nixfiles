client=$1
shift

if selection=$(printf '%s\n' "$@" | fzf --no-multi --reverse --prompt='session> ' --header='Configured Sesh sessions'); then
  if rex --autostart=false --client "$client" 'do' open_configured_session "name=$selection"; then
    exit 0
  fi
else
  status=$?
  case "$status" in
    1|130) exit 0 ;;
    *) exit "$status" ;;
  esac
fi

printf '\nCannot open session. Press Enter to close.\n' >&2
read -r _
exit 1
