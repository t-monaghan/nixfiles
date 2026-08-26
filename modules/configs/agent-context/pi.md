## AWS access

Do not run the `aws` CLI. The pi sandbox network allowlist
(`~/.pi/agent/sandbox.json`) does not include `*.amazonaws.com`, so `aws` CLI
calls always fail. For any AWS task, use the `aws-sandy` skill: the
`imds-broker` MCP server supplies credentials, and the `sandy` CLI runs AWS
SDK scripts in a Docker container. Use only the Docker backend of sandy, never
the shuru backend. If Docker fails, OrbStack is probably not running, or the
IMDS server needs a stop/create cycle — see the skill.

## spawn_worktree cleanup

Worktrees created via the `spawn_worktree` tool (or `/spawn`) live **inside the
repo** at `{{ repo_path }}/.worktrees/<sanitized-branch>` (worktrunk's
`worktree-path`, see above) plus a detached tmux session named
`pi-<sanitized-branch>`. The in-repo location is what lets pi clean them up: the
sandbox only grants write to the repo it launched in (`.`) and that repo's
`.git` dir, so a sibling worktree in `~/dev` would be unremovable.

To clean one up:

- **Remove the worktree with worktrunk**, not raw git — `wt remove <branch>`
  (add `-f` for a dirty worktree, `-D` if the branch is unmerged). This keeps
  worktrunk's state consistent and deletes the `.worktrees/<branch>` dir.
- **Kill the tmux session if it still exists.** `wt remove` does not
  garbage-collect the spawned session, so check `tmux has-session -t
  pi-<sanitized-branch>` and run `tmux kill-session -t pi-<sanitized-branch>`
  when it's still around.
