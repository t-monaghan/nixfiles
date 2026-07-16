## Shell

The user uses the fish shell, all shell commands should use fish syntax

## PR Format

PR descriptions should include the following sections:

- **Purpose** — What issue or need does this address?
- **Context** — What was happening prior, how will this address the issue?
- **Verification** — Steps taken to verify this change (or some unticked boxes for suggested steps that can verify this change)
- **Other changes** (optional) — Include this section when there are unusual or supplementary changes bundled in the PR (e.g. adding the multi-gitter flake, tooling updates, config changes unrelated to the main purpose).

## PR Comments

Never comment on GitHub on behalf of the user without being asked to.

## OpenSpec

This user uses [fission-ai/openspec](https://github.com/fission-ai/openspec) for spec-driven development. Run it with:

```bash
npx @fission-ai/openspec@latest <command>
```

### Common commands

- `npx @fission-ai/openspec@latest init` — Initialize OpenSpec in a project
- `npx @fission-ai/openspec@latest list` — List changes and specs
- `npx @fission-ai/openspec@latest view` — Interactive terminal dashboard
- `npx @fission-ai/openspec@latest validate` — Check artifacts for structural issues
- `npx @fission-ai/openspec@latest archive` — Finalize completed changes
- `npx @fission-ai/openspec@latest status` — Display artifact completion progress

## Worktrunk (`wt`)

This user manages git worktrees for parallel agent workflows with [worktrunk](https://worktrunk.dev) (`github.com/max-sixty/worktrunk`). The binary is `wt`. Worktrees share the repository's tracked files but **not** untracked/gitignored files (secrets, `.env`, build caches) — those are handled by hooks (see below). The user config is managed declaratively in nix (`modules/configs/worktrunk.nix` + `modules/configs/worktrunk-config.toml`) — edit those rather than `~/.config/worktrunk/config.toml`.

### Common commands

- `wt switch --create <branch>` (`-c`) — Create a worktree + branch and `cd` into it
- `wt switch <branch>` — Switch to an existing worktree (creates if needed)
- `wt switch` — Open the interactive picker
- Branch shortcuts: `^` (default branch), `-` (previous), `@` (current), `pr:{N}` (GitHub PR), `mr:{N}` (GitLab MR)
- `wt switch -c <branch> -x <cmd>` — Run a command after switching (e.g. `-x claude`, `-x code`); args after `--` are forwarded
- `wt list` — Show all worktrees and their status (`--full` adds CI, diffstat, LLM summaries)
- `wt merge [target]` — Squash → rebase → fast-forward target → remove worktree (defaults to default branch)
- `wt remove [branch]` — Remove worktree; deletes the branch if merged (`-f` for dirty, `-D` for unmerged)
- `wt step <op>` — Building blocks: `commit`, `squash`, `rebase`, `push`, `diff`, `copy-ignored`
- `wt hook <type> [name]` — Run a hook on demand (handy for testing); `--yes` skips approval prompts
- `-v` / `-vv` — Verbose; prints resolved template variables for hooks/aliases

### Config files

Manage with `wt config create` (user) and `wt config create --project` (project); `wt config show` prints locations and the current project identifier; `wt config shell install` installs shell integration (required for `cd`).

| File | Location | Scope | Committed |
| --- | --- | --- | --- |
| User config | `~/.config/worktrunk/config.toml` | All repos (or per-project) | ✗ |
| Project config | `.config/wt.toml` | Single repository | ✓ |

- **User config** — personal: worktree path template, LLM commit-message command, aliases, per-project overrides under `[projects."<host>/<owner>/<repo>"]`. Managed in this repo via nix.
- **Project config** — shared with teammates: hooks, dev-server URL, defaults. Project commands require one-time approval (saved to `~/.config/worktrunk/approvals.toml`).
- Any key can be overridden via env var with the `WORKTRUNK_` prefix (kebab-case → SCREAMING_SNAKE_CASE, nested levels use `__`), e.g. `WORKTRUNK_COMMIT__GENERATION__COMMAND`.

### Worktree path template

`worktree-path` controls where new worktrees go. Useful variables: `{{ repo_path }}`, `{{ repo }}`, `{{ branch }}`; filters: `sanitize` (`/`→`-`), `codename(2)` (friendly name), `hash_port` (10000–19999), `dirname`/`basename`.

```toml
# Default here: inside the repo, e.g. ~/dev/myproject/.worktrees/feature-auth
worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"
# Sibling alternative: ~/dev/myproject.feature-auth
worktree-path = "{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}"
```

Worktrees are kept **inside** the repo (under `.worktrees/`, globally gitignored) rather than as siblings. This is because pi runs in a sandbox whose only writable tree is the repo it launched in (`.`) plus the `.git` dirs at `../.git`, `../../.git`, and `../../../.git` — a sibling worktree lands in `~/dev` (read-only), so pi could create it but never `wt remove` it. In-repo worktrees keep both the working dir and `.git` metadata writable, so pi can create **and** clean them up.

### Hooks

Hooks are shell commands run at lifecycle points. `pre-*` hooks **block** (failure aborts the operation); `post-*` run in the **background** (output logged, find with `wt config state logs`). User hooks run first and need no approval; project hooks run after and require approval.

| Event | `pre-` (blocking) | `post-` (background) |
| --- | --- | --- |
| switch | pre-switch | post-switch |
| create | pre-start | post-start |
| commit | pre-commit | post-commit |
| merge | pre-merge | post-merge |
| remove | pre-remove | post-remove |

Forms (chosen by TOML shape): a string is one command; a `[table]` runs commands concurrently; a sequence of `[[hook]]` blocks runs as a pipeline (steps in order, keys within a block concurrent).

Key template variables: `{{ branch }}`, `{{ worktree_path }}`, `{{ primary_worktree_path }}`, `{{ repo }}`, `{{ repo_path }}`, `{{ default_branch }}`, `{{ target }}`, and `{{ worktree_path_of_branch('main') }}`. Variables are auto shell-escaped — don't quote `{{ ... }}`.

#### Grabbing secrets / untracked files into new worktrees

Gitignored files (secrets, `.env`, caches) don't exist in a fresh worktree. The user's secret file is `.envrc.private` (sourced by a tracked `.envrc` via direnv). It's copied into each new worktree on creation by a `pre-start` user hook in `modules/configs/worktrunk-config.toml` (applies to every repo, no approval needed):

```toml
[pre-start]
# Blocking: secrets are present before any post-start dev server / agent runs.
# '|| true' tolerates a missing source file; add more files to the list as needed.
secrets = """
for f in .envrc.private; do
  cp "{{ primary_worktree_path }}/$f" "{{ worktree_path }}/$f" 2>/dev/null || true
done
"""
```

To copy **all** gitignored files (build caches, deps, secrets) instead of a fixed list, use the built-in step — typically as `post-start` so it doesn't block:

```toml
[post-start]
copy = "wt step copy-ignored"   # add excludes via [step.copy-ignored] exclude = [".cache/"]
```

Use `{{ worktree_path_of_branch('main') }}` instead of `{{ primary_worktree_path }}` to source from a specific branch's worktree. Per-repo secret hooks can live under `[projects."<host>/<owner>/<repo>"]` in user config to keep them out of the shared project config.
