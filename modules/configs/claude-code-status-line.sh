#!/usr/bin/env bash

# Read and parse JSON input
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
session_name=$(echo "$input" | jq -r '.session_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // empty')
projdir=$(echo "$input" | jq -r '.workspace.project_dir // empty')

# Start building output
dir=$(basename "$cwd")
out=$(printf '\033[1;36m%s\033[0m' "$dir")

# Git status
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        out="$out $(printf '\033[33m %s\033[0m' "$branch")"
    fi

    status=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false status --porcelain 2>/dev/null)

    if [ -n "$status" ]; then
        mod=$(echo "$status" | grep -c '^ M\|^M')
        unt=$(echo "$status" | grep -c '^??')
        stg=$(echo "$status" | grep -c '^[MADRC]')
        st=""

        [ "$mod" -gt 0 ] && st="${st}󰏫 ($mod) "
        [ "$unt" -gt 0 ] && st="${st}󰊇 ($unt) "
        [ "$stg" -gt 0 ] && st="${st}󰶍 "

        [ -n "$st" ] && out="$out $(printf '\033[33m%s\033[0m' "$st")"
    fi
fi

# Worktree indicator
[ -n "$worktree" ] && out="$out $(printf '\033[35m│ 󰘬 %s\033[0m' "$worktree")"

# Session name
[ -n "$session_name" ] && out="$out $(printf '\033[32m│ 󰆍 %s\033[0m' "$session_name")"

# AWS profile/region - check for Granted SSO or active AWS session
if [ -n "$GRANTED_SSO_ROLE_NAME" ] || [ -n "$AWS_PROFILE" ] || [ -n "$AWS_ACCESS_KEY_ID" ]; then
    # Check for Granted SSO first, then fall back to AWS_PROFILE
    if [ -n "$GRANTED_SSO_ROLE_NAME" ]; then
        aws_profile="$GRANTED_SSO_ROLE_NAME"
    elif [ -n "$AWS_PROFILE" ]; then
        aws_profile="$AWS_PROFILE"
    else
        aws_profile="assumed"
    fi
    aws_region="${AWS_REGION:+ ($AWS_REGION)}"
    out="$out $(printf '\033[1;34m│ 󰅟 %s%s\033[0m' "$aws_profile" "$aws_region")"
fi

# Sandbox status
if [ -n "$projdir" ] && [ "$(jq -r '.sandbox.enabled // false' "$projdir/.claude/settings.local.json" 2>/dev/null)" = "true" ]; then
    out="$out $(printf '\033[32m│ 󰒃 sandbox\033[0m')"
else
    out="$out $(printf '\033[31m│ ✗ sandbox\033[0m')"
fi

# Context window usage
[ -n "$used" ] && out="$out $(printf '\033[2m│ %.0f%%\033[0m' "$used")"

echo "$out"
