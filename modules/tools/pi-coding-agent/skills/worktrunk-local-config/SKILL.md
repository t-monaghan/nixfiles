---
name: worktrunk-worktree-bootstrap
description: Write a worktrunk .config/wt.toml that auto-bootstraps a fresh git worktree's dev environment (direnv allow → warm devbox → install deps → generate code) without tripping over direnv/devbox ordering races. Use when setting up worktrunk hooks for any direnv + devbox repo, regardless of toolchain (just, Node/pnpm, Go, Make, …).
---

# Bootstrapping a worktrunk worktree in a direnv + devbox repo

How to write a (typically **local**) `.config/wt.toml` so a freshly-created
[worktrunk](https://worktrunk.dev) worktree brings its dev environment up
automatically: allow direnv → warm devbox → install dependencies → generate any
checked-out-but-not-committed code.

The commands themselves are trivial. The hard part is **ordering them around two
races** between worktrunk's background hooks and your interactive shell's direnv
integration. This skill captures the recipe *and* the reasoning, so you can adapt
it to whatever toolchain a repo uses.

> Applies to any repo where **direnv loads a devbox environment**. The worked
> examples use `just` + Node and `devbox` + Go, but the design is toolchain-
> agnostic — swap in `make`, `cargo`, `uv`, `pnpm`, etc.

---

## TL;DR — the shape

`.config/wt.toml`:

```toml
[pre-start]   # BLOCKING — runs to completion before `wt switch` returns
prepare = "direnv allow {{ worktree_path }} && (direnv exec {{ worktree_path }} true || true)"

[post-start]  # background — `wt switch` returns immediately
setup = """
cd {{ worktree_path }} &&
direnv exec . <install-deps> &&
direnv exec . <generate-code>
"""
```

Replace `<install-deps>` / `<generate-code>` with your toolchain (examples
below). Add `.config/.gitignore` to keep it local (see
[Keep it local](#keep-it-local-configgitignore)).

The rest of this skill explains every line.

---

## How direnv + devbox fit together

Get this model straight first — the hook design falls out of it.

- **`.envrc` is TRACKED.** A fresh worktree has it immediately, byte-identical to
  every other worktree. It typically does `eval "$(devbox generate direnv
  --print-envrc)"` (plus maybe some exports and a `source_env_if_exists` for
  secrets).
- **devbox provides the toolchain.** `just`, `go`, `node`, `pnpm`, `make`, … come
  from devbox (declared in the tracked `devbox.json`) and are **only on `PATH`
  once direnv has loaded the devbox env.** `devbox` *itself* is usually on a
  global `PATH` (e.g. a nix profile), so it's callable from a hook even before
  direnv loads — but the tools it provides are not.
- **`.devbox/` is gitignored and must NOT be copied between worktrees.** It holds
  a virtenv with **relative symlinks computed for the source worktree's depth**;
  copied into a different path they dangle and tools like `corepack enable` fail
  with `EEXIST`. direnv rebuilds `.devbox` correctly *per worktree* on first load.
- **Other gitignored artifacts must be regenerated, not copied.** `node_modules/`,
  `target/`, generated code (e.g. provider bindings, `*_gen.go`, protobuf output)
  — anything gitignored and path/host-sensitive — should be rebuilt in the new
  worktree, which is exactly what the `post-start` step does.

### direnv's allow mechanism (the thing that bites you)

`direnv exec` and the shell hook refuse to load an `.envrc` unless it's been
*allowed*. The allow database lives at `~/.local/share/direnv/allow/`. Each entry
is a file:

- **filename** = `sha256( "<absolute path to .envrc>" + "\n" + "<file contents>" )`
- **contents** = that absolute path

`direnv allow <dir>` finds `<dir>/.envrc`, computes that hash, writes the entry.
On load, direnv recomputes the hash and looks for a matching file. **No match ⇒
`.envrc is blocked`.** Two consequences:

1. The allow is **per-worktree** (the path is in the hash), so every new worktree
   must be allowed afresh.
2. "blocked" almost always means *the allow entry didn't exist yet at the moment
   of the load* — an **ordering/timing bug**, not a hashing bug. Confirm by
   reproducing the filename:
   ```bash
   { printf '%s\n' "$PWD/.envrc"; cat .envrc; } | shasum -a 256
   # should equal a filename under ~/.local/share/direnv/allow/
   ```

---

## The two races you must design around

Both surface as `direnv: error /.../.envrc is blocked`.

### Race 1 — background `post-start` steps are not strictly ordered

The intuitive first attempt is a `[[post-start]]` *pipeline*:

```toml
# ❌ DON'T — splits "allow" from "exec" across separate background steps
[[post-start]]
allow = "direnv allow {{ worktree_path }}"
[[post-start]]
deps  = "direnv exec {{ worktree_path }} <install-deps>"
```

In practice the `deps` step's `direnv exec` can race **ahead of** the `allow`
step and hit "blocked", even though the allow entry gets written correctly a
moment later. **Don't rely on separate background steps running in strict
order.** Chain dependent commands with `&&` in a *single* shell command.

### Race 2 — background `direnv allow` vs your interactive shell

Even with allow+exec chained in one command, if it runs in the **background**
(`post-start`):

1. `wt switch` creates the worktree, kicks off the background hook, returns.
2. Your shell cd's into the worktree; direnv's shell hook fires on the **first
   prompt** — but the background `direnv allow` hasn't finished → **first prompt
   is "blocked", no toolchain env, no `.devbox`**.
3. The background allow finishes; by the **second prompt** direnv loads and the
   env finally appears.

Symptom: *"the first terminal prompt doesn't have the env, but the second does."*
The allow has to win the race against your own shell, so it **cannot** live in
the background.

---

## The design: `pre-start` (blocking) vs `post-start` (background)

Split work by **when it must happen**:

| Hook | Timing | Put here |
| --- | --- | --- |
| `pre-start` | **Blocking** — completes before `wt switch` returns and your shell cd's in | Anything the first prompt depends on |
| `post-start` | **Background** — `wt switch` returns immediately | Slow work nothing is waiting on |

So:

- **`direnv allow` → `pre-start`.** It finishes before your shell lands in the
  worktree, so the first prompt loads cleanly. This also defeats Race 1: by the
  time `post-start` runs `direnv exec`, the env is already allowed.
- **Warm devbox in `pre-start` too** — `direnv exec {{ worktree_path }} true`.
  Once allow is unblocked, *both* your first interactive prompt *and* the
  background install/generate steps will try to build `.devbox` — concurrently.
  Loading the env once, up front, builds `.devbox` a single time; everyone else
  reuses it. Make it best-effort with `&& (… || true)`: a devbox hiccup then
  warms nothing but doesn't **abort the worktree** (a failing `pre-start` aborts
  `wt switch`), while the strict `&&` keeps `direnv allow` a hard requirement.
- **Slow install/codegen → `post-start`.** Nothing on the first prompt needs them
  done. One chained command (`&&`) enforces any dependency order (e.g. install
  deps *before* generating code that imports them).

---

## The `direnv exec` / cwd gotcha (why `cd` first)

`direnv exec <dir> <cmd>` loads the env for `<dir>` **but does not `cd` into it** —
`<cmd>` runs in the hook's current directory. Many build tools resolve their work
relative to the cwd, so this matters:

- `just` searches **upward** for a `justfile` — from the *primary* worktree's cwd
  it would find that worktree's justfile and operate on the **wrong tree**.
- `make` reads the `Makefile` in the cwd; `go` acts on the module rooted at the
  cwd; `npm`/`pnpm` install into the cwd's `package.json`.

Defences, used together:

- `cd {{ worktree_path }}` at the start of the `post-start` command, then
  `direnv exec . …` (`.` = the worktree you just cd'd into).
- In `pre-start`, pass the explicit `{{ worktree_path }}` to `direnv allow` /
  `direnv exec` rather than assuming the hook's cwd.

(worktrunk auto shell-escapes `{{ … }}`, so don't quote it.)

> **Alternative to `direnv exec`:** `devbox run -c {{ worktree_path }} -- <cmd>`
> activates the devbox env *without* needing a direnv allow at all (handy if you'd
> rather not depend on the allow DB for background steps). It loads the
> devbox-declared env only, not any extra exports your `.envrc` adds.

---

## Worked examples (swap in your toolchain)

The `pre-start` block is identical in every case — only `post-start` changes.

### `just` + Node/pnpm

A repo whose `justfile` defines `install` (→ `pnpm install`) and `init`
(→ generate code that needs `node_modules`). `just` searches upward for the
justfile, so `cd` first:

```toml
[post-start]
setup = """
cd {{ worktree_path }} &&
direnv exec . just install &&
direnv exec . just init
"""
```

### devbox + Go

Same skeleton, Go commands. Fetch modules, then run code generation:

```toml
[post-start]
setup = """
cd {{ worktree_path }} &&
direnv exec . go mod download &&
direnv exec . go generate ./...
"""
```

### Other toolchains

```toml
# Rust:   direnv exec . cargo fetch && direnv exec . cargo build
# Make:   direnv exec . make deps && direnv exec . make generate
# Python: direnv exec . uv sync
```

The ordering rule is always the same: put steps that depend on an earlier step
(generated code needing fetched deps) **after** it in the same `&&` chain.

---

## Hook forms (worktrunk) — quick reference

The TOML *shape* picks the form (`wt hook --help`):

- **string** → one command: `pre-start = "…"`
- **`[table]`** → keys run **concurrently** (independent jobs).
- **`[[block]]` sequence** → a pipeline: blocks in order, keys within a block
  concurrent. *But* don't lean on this for ordering across **background**
  (`post-start`) steps — see Race 1. For a hard dependency chain, use `&&` inside
  a single command.

Also:
- `pre-*` failure **aborts** the operation; `post-*` runs in the background (find
  logs with `wt config state logs`).
- **Project** hooks (in `.config/wt.toml`) require one-time **approval** on first
  run, and again whenever the command text changes (stored in
  `~/.config/worktrunk/approvals.toml`; `--yes` bypasses for automation). **User**
  hooks (in `~/.config/worktrunk/config.toml`) run first and need no approval.
- Inspect configured hooks with `wt hook show`.

---

## Keep it local: `.config/.gitignore`

If this config is personal (not something teammates should inherit), keep it out
of the repo. Add `.config/.gitignore` that ignores the whole directory:

```gitignore
# Ignore the entire .config/ directory — local worktrunk config (.config/wt.toml),
# not shared. `*` ignores every entry here (including this .gitignore itself).
*
```

`*` ignores everything in `.config/` (including `wt.toml` **and** the
`.gitignore`). git still applies these rules even though the `.gitignore` is
untracked, so `git status` never shows `.config/`. Verify:

```bash
git check-ignore -v .config/wt.toml   # → .config/.gitignore:<n>:*  .config/wt.toml
git status --short .config            # → (empty)
```

**Caveat:** a gitignored config isn't propagated to new worktrees via git (which
share only *tracked* files). Run `wt` commands from your primary worktree (which
has `.config/wt.toml`) so the project config is read. (If you also want it
*inside* every worktree, a user-level `wt step copy-ignored` hook copies
gitignored files across.) To share with teammates instead, **don't** add the
`.gitignore` and commit `.config/wt.toml`.

---

## Build it from scratch (checklist)

1. **Write `.config/wt.toml`** with the `[pre-start]` + `[post-start]` blocks from
   the [TL;DR](#tldr--the-shape), substituting your toolchain's install/codegen
   commands.
2. **Decide local vs shared.** Local → add `.config/.gitignore` (`*`) and verify
   with `git check-ignore` / `git status`. Shared → skip the ignore and commit.
3. **Validate parsing:** `wt hook show` — expect `pre-start prepare` and
   `post-start setup`.
4. **Test:** `wt switch --create <branch>`, approve when prompted. Expected: a
   brief pause (allow + devbox warm), then the **first prompt** has the env with
   **no "blocked"**; install/codegen run in the background — watch with
   `wt config state logs`.
5. Change a command later → re-approve when prompted (the text changed).
