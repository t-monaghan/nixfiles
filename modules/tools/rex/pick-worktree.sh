client=$1

pick() {
  local status
  if selection=$(fzf --no-multi --reverse "$@"); then
    return 0
  else
    status=$?
    case "$status" in
      1|130) exit 0 ;;
      *) exit "$status" ;;
    esac
  fi
}

fail() {
  printf '\n%s\nPress Enter to close.\n' "$1" >&2
  read -r _
  exit 1
}

current=''
if [ -n "${2:-}" ]; then
  current=$(git -C "$2" rev-parse --show-toplevel 2>/dev/null) || current=''
fi
repos=$(zoxide query -l --base-dir "$HOME/dev" --exclude "$HOME/dev") || repos=''
repos=$(
  {
    if [ -n "$current" ]; then printf '%s\n' "$current"; fi
    printf '%s\n' "$repos"
  } | jq -Rrs 'split("\n") | reduce .[] as $path ([]; if $path == "" or index($path) then . else . + [$path] end) | .[]'
)
[ -n "$repos" ] || fail 'No repositories found. Visit a repository first.'
repo_rows=$(printf '%s\n' "$repos" | jq -Rr --arg prefix "$HOME/dev/" '[., ltrimstr($prefix)] | @tsv')
pick --no-sort --scheme=path --delimiter='\t' --with-nth=2.. --prompt='repo> ' <<< "$repo_rows"
IFS=$'\t' read -r repodir _ <<< "$selection"
cd "$repodir" || fail 'Cannot open the selected repository.'
root=$(git rev-parse --show-toplevel) || fail 'The selected directory is not a Git repository.'
worktrees=$(wt list --format=json) || fail 'Cannot list worktrees.'
main=$(printf '%s\n' "$worktrees" | jq -r '[.items[] | select(.worktree.main == true) | .worktree.path][0] // empty') || fail 'Cannot read Worktrunk output.'
repo=$(basename "${main:-$root}")
prs=$(gh pr list --state all --limit 100 --json number,headRefName,state,title,updatedAt 2>/dev/null) || prs='[]'
rows=$(printf '%s\n' "$worktrees" | jq -r --argjson prs "$prs" -f "$REX_WORKTREE_ROWS") || fail 'Cannot read Worktrunk output.'
[ -n "$rows" ] || fail 'No worktrees or open PRs found.'
pick --delimiter='\t' --with-nth=4.. --prompt="wt/pr ($repo)> " <<< "$rows"
IFS=$'\t' read -r kind key number _ <<< "$selection"

case "$kind" in
  wt)
    path=$key
    branch=$(git -C "$path" symbolic-ref --quiet --short HEAD) || branch=$(basename "$path")
    ;;
  pr)
    # shellcheck disable=SC2016
    result=$(fish -c 'wt switch --no-cd --format json $argv[1]' -- "pr:$key") || fail "Worktrunk failed for PR #$key."
    path=$(printf '%s\n' "$result" | jq -er '.path') || fail 'Worktrunk returned no path.'
    branch=$(git -C "$path" symbolic-ref --quiet --short HEAD) || branch="pr-$key"
    ;;
  *) fail 'Unknown picker entry.' ;;
esac

if [ "$number" != '-' ]; then
  name="$repo #$number"
else
  name="$repo: $branch"
fi
rex --autostart=false --client "$client" 'do' open_worktree "name=$name" "path=$path" \
  || fail "Cannot open $name in Rex."
