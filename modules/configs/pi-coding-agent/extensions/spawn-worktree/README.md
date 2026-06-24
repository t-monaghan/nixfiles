# spawn-worktree

Pi extension that forks an independent `pi` agent into a fresh git worktree,
combining [worktrunk](https://worktrunk.dev) (`wt`) for worktree creation with
tmux for a detached, attachable session.

## What it does

Given a branch name and a task, the extension:

1. Verifies `wt` and `tmux` are on PATH and validates the branch name.
2. Looks up the worktree via `wt list --format json`. If the branch already
   has a worktree it's reused; otherwise it's created via
   `wt switch -c <branch> -x true` (which creates the worktree and immediately
   exits — `-x true` replaces the `wt` process with `/bin/true`). Worktrunk's
   `worktree-path` puts it **inside** the repo at
   `<repo>/.worktrees/<sanitized-branch>` (see
   `modules/configs/worktrunk-config.toml`), which is what lets a sandboxed pi
   later `wt remove` it — a sibling worktree in `~/dev` would be read-only to
   the sandbox.
3. Starts a **detached** tmux session named `pi-<sanitized-branch>` rooted at
   the new worktree path, running `pi <task>` in interactive mode.
4. Returns the session name and worktree path so you can attach later.

The spawned pi runs in interactive mode, so once it finishes the initial turn
it sits at the prompt waiting for steering. Your existing `tmux-notify.ts`
extension brackets the session name when it needs input, so backgrounded
agents surface in the tmux status line.

## Surfaces

| Surface              | Caller         | Usage                                                      |
| -------------------- | -------------- | ---------------------------------------------------------- |
| `/spawn` command     | you (slash)    | `/spawn feature-foo Implement the X feature in src/foo.ts` |
| `spawn_worktree` tool | LLM (tool call) | Agent picks it for parallelisable, context-isolated work   |

The LLM tool accepts `{ branch, task, baseBranch?, model?, sessionName? }`.

## Attaching to a background agent

```fish
sesh connect pi-feature-foo
# or
tmux attach -t pi-feature-foo
```

Detach with the usual tmux prefix + `d`. Kill with
`tmux kill-session -t pi-feature-foo`.

## Cleaning up a spawned worktree

```fish
wt remove feature-foo                 # -f if dirty, -D if unmerged; removes .worktrees/feature-foo
tmux kill-session -t pi-feature-foo   # wt remove won't kill the session; do it if it still exists
```

Always remove via `wt` (not raw `git worktree remove`) so worktrunk's state
stays consistent.

## Why interactive + tmux (not `pi -p` + `spawn detached`)

- `pi -p` would exit after the first turn — no way to follow up.
- Bare detached `spawn(..., { detached: true, stdio: 'ignore' })` denies pi
  a pty, which the TUI needs. tmux supplies the pty and a way back in.
- tmux session names work as natural handles for `sesh`, `wt list`, and any
  future "list my background agents" tooling.

## Requirements

- `wt` (worktrunk) — already in `modules/configs/worktrunk.nix`
- `tmux` — already in `modules/configs/tmux.nix`
- Optional: `sesh` (already configured) for fuzzy reattachment.

## Limitations / future work

- No "foreground subagent" mode. If you want streamed inline output, use the
  upstream [`subagent` example](../../../../../../nix/store/.../examples/extensions/subagent/)
  pattern with `cwd` set to the worktree path.
- Doesn't pass through `--append-system-prompt`, extra flags, or env tweaks.
- Doesn't garbage-collect dead tmux sessions; that's `tmux kill-session`'s job.
- Doesn't currently support `wt switch` shortcuts (`pr:{N}`, `^`, `-`, `@`) —
  expects a literal branch name.

## Wiring

Picked up automatically by pi's extension discovery once the file lives at
`~/.pi/agent/extensions/spawn-worktree/index.ts`. The
`home.file.".pi/agent"` recursive copy in `modules/home.nix` already handles
that — no additional nix changes needed.
