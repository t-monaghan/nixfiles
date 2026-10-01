# spawn-worktree

Pi extension that starts an independent interactive `pi` agent in a git
worktree and a new window in the **current tmux session**. Run it from a tmux
pane.

## What it does

1. Checks for `wt` and `tmux`, validates the branch, and finds the current
   tmux session from `TMUX_PANE`.
2. Reuses an existing worktree or creates one with
   `wt switch -c <branch> -x true`. Worktrunk's `worktree-path` puts it inside
   the repository at `<repo>/.worktrees/<sanitized-branch>`. This lets a
   sandboxed pi remove it later.
3. Starts `pi <task>` in a detached window named `pi-<sanitized-branch>` in
   the current session. The current window remains selected.
4. Returns the window ID and worktree path. Select the window to inspect or
   steer the agent.

## Surfaces

| Surface | Caller | Usage |
| --- | --- | --- |
| `/spawn` command | you | `/spawn feature-foo Implement the X feature in src/foo.ts` |
| `spawn_worktree` tool | agent | Independent work in a separate context |

The tool accepts `{ branch, task, baseBranch?, model?, windowName? }`.
A window with the same name in the current session causes an error.

## Select and clean up the window

From within the same tmux session, select the window by its ID as returned by
`/spawn` or `spawn_worktree`. Close the window before removing the worktree:

```fish
tmux select-window -t '@123'
tmux kill-window -t '@123'
wt remove feature-foo # use -f if dirty, -D if unmerged
```

Use `wt remove`, not `git worktree remove`, to keep worktrunk state consistent.
The `wtclean` fish function also closes windows whose active pane is in a
worktree it removes.

The agent runs in interactive mode, so it waits for input after its first
turn. tmux supplies the pty that the pi TUI needs. `tmux-notify.ts` brackets
the **session** name when an agent needs input, even though the agent now runs
in a window of the current session.

## Requirements

- `wt` (worktrunk) — `modules/configs/worktrunk.nix`
- `tmux` — `modules/configs/tmux.nix`; run pi from inside tmux

## Related dispatcher workflow

For single-turn asynchronous agents across named repositories, use a repo-less
dispatcher session instead. Press `C-b M` and see
[`../dispatch/README.md`](../dispatch/README.md).

## Limitations

- No foreground subagent mode.
- Does not pass through `--append-system-prompt`, extra flags, or env tweaks.
- Does not support `wt switch` shortcuts (`pr:{N}`, `^`, `-`, `@`).

## Wiring

Pi discovers the extension at `~/.pi/agent/extensions/spawn-worktree/index.ts`.
The recursive `home.file.".pi/agent"` copy in `modules/home.nix` installs it.
