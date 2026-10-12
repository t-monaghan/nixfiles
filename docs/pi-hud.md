# Pi sessions in HUD

The **Pi sessions** section in `modules/configs/hud.nix` uses `pi-hud`. It lists
saved pi sessions from `~/.pi/agent/sessions` and dispatcher job session
folders under `~/dev/agents/sessions`. Set `PI_HUD_SESSION_DIRS` to a
colon-separated list for other session directories. It also reads live records written by
`extensions/hud-registry.ts`. The index caches session metadata under
`~/.cache/pi-hud`; live records are under `~/.local/state/pi-hud`.

Enter selects an active interactive pi pane. For a saved session, Enter creates
a pi window in the repository's base tmux session. The pi process still runs in
the session's original working directory. Enter on a running dispatcher job
creates a status window: dispatcher jobs have no interactive tmux pane. Sessions
with removed working directories remain listed but cannot be resumed until the
original directory is restored. Live records begin when a pi process starts or
reloads the extension; existing pi processes must run `/reload` or restart.

The helper resolves worktrees with `git worktree list --porcelain`. It does not
infer the base repository from `.worktrees/` or require a worktree name format.
It does not remove worktrees or sessions. `--no-session` processes appear only
while the process is active.

## Worktree management

Keep worktrunk for agent work. `spawn_worktree`, dispatcher jobs, the PR path
wrapper, and `wt remove` use worktrunk. The existing worktrunk `post-start`
hook copies ignored files, including environment files, into new worktrees.

Sesh 2.32.0 `worktree connect` can create an issue/PR worktree and connect to
its tmux session. This replaces separate issue lookup, worktree creation, and
tmux connection steps for an issue/PR workflow. It creates a **separate tmux
session per worktree** and recognizes numerically named worktrees. This differs
from the base-session layout and existing branch-named worktrees. It does not
index pi sessions or provide an equivalent of `wt remove`. Do not replace
worktrunk for agent work without changing those workflows.

For a separate sesh worktree pilot, configure the repository's `[[worktree]]`
`create_command` to run a trusted setup helper. That helper must copy an
explicit allowlist such as `.env.local` and `.envrc.private` from the base
repository to the new worktree **before** starting pi or direnv. It must check
that each destination is ignored and not tracked, preserve restrictive
permissions, and refuse to overwrite existing files. Never put secret contents
in a Nix-generated command or symlink a worktree secret to the base secret.
Exclude `.devbox` and other generated directories. Sesh runs `create_command`
only when it creates a worktree and starts a tmux session; `startup_command`
runs instead when the worktree already exists and the tmux session is new. A
repair command is required for existing worktrees or failed setup.
