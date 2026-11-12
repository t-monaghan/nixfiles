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
`worktree-path`, see above). The tool opens the worktree in the current Rex
pane, gives the pane a short change-related name, and replaces the current pi
session with a fresh pi session. It does not create a Rex session or a parallel
agent. Use it only when the user wants to switch the current pane to a worktree.
The in-repo location lets a sandboxed pi remove the worktree later.

To clean one up:

- **Exit the worktree's pi session and leave its directory.** No separate Rex
  session was created. Do not kill the shared Rex session.
- **Remove the worktree with worktrunk**, not raw git — `wt remove <branch>`
  (add `-f` for a dirty worktree, `-D` if the branch is unmerged). This keeps
  worktrunk's state consistent and deletes the `.worktrees/<branch>` dir.
