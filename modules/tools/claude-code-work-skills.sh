#!/usr/bin/env bash
set -euo pipefail

repo_root=$1
skills_root=$2
mkdir -p "$repo_root" "$skills_root"

for spec in sre-health-triage:.claude/skills sre-ai-toolkit:skills ca-agent-context:skills; do
  repo=${spec%%:*}
  source_dir=${spec#*:}
  checkout="$repo_root/$repo"
  if [[ -d "$checkout/.git" ]]; then
    git -C "$checkout" pull --ff-only origin main
  else
    git clone --depth 1 --branch main "http://github.com/cultureamp/$repo.git" "$checkout"
  fi

  for skill in "$checkout/$source_dir"/*; do
    [[ -f "$skill/SKILL.md" ]] || continue
    target="$skills_root/${skill##*/}"
    if [[ -L "$target" && "$(readlink "$target")" == "$skill" ]]; then
      continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
      printf 'Refusing to replace existing skill: %s\n' "$target" >&2
      exit 1
    fi
    ln -s "$skill" "$target"
  done
done
