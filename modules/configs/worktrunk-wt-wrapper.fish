# Worktrunk `wt` wrapper — name NEW worktrees by their GitHub PR number when one
# exists, falling back to the branch name.
#
# Managed by nix (modules/configs/worktrunk.nix). The activation script installs
# worktrunk's own shell integration under the name `__wt_core` and drops this
# file in as `functions/wt.fish`, so `wt` calls this wrapper and this wrapper
# delegates to `__wt_core` (which keeps worktrunk's cd/exec directive handling).
#
# WHY A WRAPPER: worktrunk's `worktree-path` template only exposes
# repo_path/repo/owner/branch — there is no PR-number variable, and the path is
# fixed at CREATION time. But `wt` accepts a per-invocation
# `--config-set worktree-path="…"` override, so we compute the path ourselves
# and inject it. The default template in worktrunk-config.toml stays branch-based
# and acts as the fallback.
#
# STABILITY: the override only takes effect when a worktree is CREATED —
# worktrunk locates an existing worktree via its branch→path git mapping and
# ignores the template. We additionally short-circuit (and skip the `gh` lookup)
# when a worktree already exists for the branch, so routine switching between
# existing worktrees pays no network cost and never gets renamed out from under
# you when a PR is opened after the branch's worktree already exists.

function wt --wraps wt --description 'worktrunk: name new worktrees by GitHub PR number when available'
    # Only augment `switch`; everything else passes straight through.
    if test (count $argv) -eq 0; or test "$argv[1]" != switch
        __wt_core $argv
        return $status
    end

    # Find the target: an explicit `pr:N` shortcut gives the number directly;
    # otherwise the first bare token is the branch. Skip value-taking flags and
    # stop at `--` (everything after is --execute's args, not the branch).
    set -l pr ''
    set -l branch ''
    set -l i 2
    set -l n (count $argv)
    while test $i -le $n
        switch $argv[$i]
            case --
                break
            case -b --base -x --execute --config --format -C
                set i (math $i + 2)
                continue
            case 'pr:*'
                set pr (string replace 'pr:' '' -- $argv[$i])
                break
            case 'mr:*' '^' '-' '@'
                # GitLab MR / default / previous / current — not PR-named.
            case '-*'
                # valueless flag (-c/--create, --no-cd, --clobber, …): ignore.
            case '*'
                set branch $argv[$i]
                break
        end
        set i (math $i + 1)
    end

    # If a worktree already exists for this branch the override is a no-op, so
    # short-circuit before spending a `gh` round-trip.
    if test -n "$branch"
        if git worktree list --porcelain 2>/dev/null | string match -q "branch refs/heads/$branch"
            __wt_core $argv
            return $status
        end
    end

    # No explicit pr:N → ask GitHub whether the branch has an open PR. Any
    # failure (no gh, not authed, not a GitHub repo, no PR) yields an empty
    # string and we fall back to the branch-based default path.
    if test -z "$pr"; and test -n "$branch"
        set pr (gh pr list --head $branch --state open --json number --jq '.[0].number // empty' 2>/dev/null)
    end

    if test -n "$pr"
        __wt_core --config-set "worktree-path=\"{{ repo_path }}/.worktrees/pr-$pr\"" $argv
    else
        __wt_core $argv
    end
    return $status
end
