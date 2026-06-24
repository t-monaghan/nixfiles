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
