# dispatch

Pi extension for a repo-less dispatcher session that starts asynchronous agents in shared Worktrunk worktrees.

## Start a dispatcher

Press `C-b M` in tmux. This creates and opens a unique `dispatch-<timestamp>` tmux session with cwd `~/dev/agents`.

The extension only registers its surfaces when pi's cwd is exactly the configured agent root. Normal repository sessions are unchanged.

## Dispatch an agent

Ask pi to delegate repository work. The model calls:

```text
dispatch_worktree_agent({ repo, branch, task, base?, model? })
```

`repo` is relative to `~/dev`. The extension:

1. Creates or reuses the branch worktree with Worktrunk.
2. Sets `WT_WORKTREE_ROOT=~/dev/agents/worktrees`, which makes the fish `wt` wrapper place new worktrees under that directory while preserving PR-number paths.
3. Starts `pi --print --mode json` in a detached process in the worktree.
4. Returns immediately and records the job under the dispatcher session.
5. Adds the result, tool-call summary, Git summary, usage, and resume command to the dispatcher session when the process finishes.

The default model and paths are in `~/.pi/agent/dispatch.json` and are managed by `pi-coding-agent.nix`.

## Inspect jobs

```text
/agents
/agents show <job-id>
/agents cancel <job-id>
```

The full event stream, stderr, and pi session remain under:

```text
~/dev/agents/sessions/<dispatcher-session-id>/<job-id>/
```

A worktree agent continues if the dispatcher exits. Resume it from the path shown in its completion message.

## Cleanup

The extension never removes worktrees. Remove one from its repository with Worktrunk:

```fish
wt -C ~/dev/<repo> remove <branch>
```

Completed session records remain under `~/dev/agents/sessions` until removed manually.

## Concurrency

Each dispatcher session permits five running agents by default. Multiple dispatcher sessions have separate job registries and limits.
