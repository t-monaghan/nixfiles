# spawn-worktree

Pi extension that opens a git worktree in the **current Rex pane**. It ends the
current pi session and starts a fresh pi session in the worktree. It does not
create a Rex session, window, or split.

## What it does

1. Requires interactive pi inside Rex, `wt`, `rex`, `pi`, and Node with
   `process.execve` support. Checks the current pane using `REX_SESSION` and
   `REX_BLOCK`. It does not use the pane that happens to have app focus.
2. Reuses an existing worktree or creates one with
   `wt switch -c <branch> -x true`. Worktrunk's `worktree-path` puts new
   worktrees inside the repository at `<repo>/.worktrees/<sanitized-branch>`.
3. Renames the current Rex pane to a short change-related name. The default is
   the last branch component, limited to 40 characters. For example,
   `feature/rex-worktree` becomes `rex-worktree`.
4. Requests normal pi shutdown. After pi saves the session, runs extension
   cleanup, and restores the terminal, it replaces its process with `pi <task>`
   in the worktree. The Rex pane and process ID stay the same. A failed shutdown
   does not start the replacement.

The original pi session remains saved and can be resumed later. The new pi
session does not receive the original conversation. It receives the task and
worktree-agent guidance below.

## Interfaces

| Interface | Caller | Usage |
| --- | --- | --- |
| `/spawn` command | you | `/spawn feature/rex-worktree Update the worktree extension` |
| `spawn_worktree` tool | agent | Switch the current pane to a worktree with a fresh pi session |

The tool accepts `{ branch, task, baseBranch?, model?, paneName? }`.
Set `paneName` to a short name relevant to the change, at most 40 characters.
The old `sessionName` and `windowName` parameters remain aliases for `paneName`;
`paneName` takes precedence. These aliases do not rename a Rex session or window.
Both interfaces use the configured default model. Omit `model` unless the user
explicitly requests a specific model.

Use the tool only when the user wants to replace the current pi session. It no
longer starts a parallel agent. The tool ends the current agent turn before
shutdown. `/spawn` waits for the current agent turn to finish before proceeding.

## Agent guidance

Use repository conventions and record reasonable assumptions. Ask only when
missing information or approval is critical to safe, correct work. If input is
unavailable, report the blocker instead of guessing.

For implementation tasks, the default result is verified changes, a commit, a
pushed branch, and a draft PR. Create or update the draft PR and report its URL;
do not merge it. Follow explicit task instructions when they specify a different
result. In personal repositories that rarely use PRs, follow the repository
workflow instead. Report verification results and explain why no PR was created
when this default does not apply or cannot be completed.

This guidance is included in the initial prompt for both `/spawn` and
`spawn_worktree`.

## Cleanup

Exit the worktree's pi session and leave the worktree directory before removing
the worktree. Use `wt remove <branch>` (use `-f` if dirty, `-D` if unmerged), not
`git worktree remove`, to keep worktrunk state consistent.

No separate Rex session was created. Do not kill the shared Rex session as part
of worktree cleanup. The pane keeps its short name until renamed again.

## Requirements

- `wt` (worktrunk) — `modules/tools/worktrunk.nix`
- `rex` and a running Rex server — `modules/tools/rex.nix`
- Interactive pi inside a Rex pane, on a platform with Node `process.execve`

## Related dispatcher workflow

For single-turn asynchronous agents across named repositories, use a repo-less
dispatcher session instead. See [`../dispatch/README.md`](../dispatch/README.md).

## Limitations

- Not available in print, JSON, or RPC mode.
- Does not pass through `--append-system-prompt`, extra flags, or env tweaks.
- Does not support `wt switch` shortcuts (`pr:{N}`, `^`, `-`, `@`).
- Failures during worktree creation or pane renaming keep the current pi session
  running. A created worktree is not automatically removed on failure.

## Verification

Run `node --test modules/tools/pi-coding-agent/extensions/spawn-worktree/spawn.test.ts`.
The tests require `PI_SESSION_TEMP`. They mock worktrunk and Rex commands and
check process replacement in a child process with a temporary `pi` executable.
They do not replace the test runner or create real worktrees or Rex sessions.

## Wiring

Pi discovers the extension at `~/.pi/agent/extensions/spawn-worktree/index.ts`.
The recursive `home.file.".pi/agent"` copy in `modules/tools/pi-coding-agent.nix` installs it.
