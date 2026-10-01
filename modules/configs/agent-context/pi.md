## AWS access

Do not run the `aws` CLI. The pi sandbox network allowlist
(`~/.pi/agent/sandbox.json`) does not include `*.amazonaws.com`, so `aws` CLI
calls always fail. For any AWS task, use the `aws-sandy` skill: the
`imds-broker` MCP server supplies credentials, and the `sandy` CLI runs AWS
SDK scripts in a Docker container. Use only the Docker backend of sandy, never
the shuru backend. If Docker fails, check `docker info` and the skill's IMDS
server recovery steps.

## Dispatch worktree agents

A pi session started in `~/dev/agents` is a repo-less dispatcher session. Use
`dispatch_worktree_agent` to run single-turn asynchronous agents in named
repositories under `~/dev`. New worktrees live under
`~/dev/agents/worktrees/<repo>/`; existing worktrees can be reused. Use
`/agents` to list jobs. The dispatcher records completed agent results in its
own history. It does not remove worktrees.

## spawn_worktree cleanup

Worktrees created via the `spawn_worktree` tool (or `/spawn`) live **inside the
repo** at `{{ repo_path }}/.worktrees/<sanitized-branch>` (worktrunk's
`worktree-path`, see above) plus a detached tmux window named
`pi-<sanitized-branch>` in the current session. The in-repo location lets pi
clean them up: the sandbox only grants write to the repo it launched in (`.`) and that repo's
`.git` dir, so a sibling worktree in `~/dev` would be unremovable.

To clean one up:

- **Kill the tmux window if it still exists.** Use the window ID returned by
  `spawn_worktree` with `tmux kill-window -t <window-id>`. Do not kill the
  shared session.
- **Remove the worktree with worktrunk**, not raw git — `wt remove <branch>`
  (add `-f` for a dirty worktree, `-D` if the branch is unmerged). This keeps
  worktrunk's state consistent and deletes the `.worktrees/<branch>` dir.
