# Pi sandbox findings

## Purpose

This document records Pi tool calls that failed because of sandbox restrictions. The evidence comes from Agentsview session transcripts. The recommendations refer to `modules/configs/pi-coding-agent/sandbox.json`.

## Summary

Agentsview returned more than 60 results with the generic `OS-level sandbox restriction` wrapper. Some results were normal command failures that the wrapper classified as sandbox failures. The sections below contain failures with clear sandbox evidence.

## Confirmed failures

| Failure | Agentsview evidence | Assessment |
| --- | --- | --- |
| Nix reads `~/.nix-defexpr/channels` | Repeated `posix_stat: Operation not permitted` errors during `nix-instantiate` and `nix flake` | The current `allowRead` list does not include `~/.nix-defexpr`. |
| macOS temporary directory writes | Repeated `mktemp`, `mkdir`, copy, and heredoc failures under `/var/folders/...` | `extensions/session-temp.ts` now addresses this problem by putting `PI_SESSION_TEMP` under `/tmp/claude`. |
| Linked worktree Git metadata | Commits and upstream configuration failed when a worktree `.git` file referred to another repository directory | The current uncommitted `~/dev/*/.git` and `~/dev/*/.git/**` entries address the historical sibling-worktree failures. |
| Worktree creation | `wt switch` failed while creating files such as `.vscode` in a worktree outside the writable project directory | In-repository worktrees or dispatcher worktrees under `~/dev/agents/worktrees` avoid this problem. |
| zoxide database | zoxide failed to create `~/Library/Application Support/zoxide/tmp_*` with `Operation not permitted` | `~/Library` is readable, but the zoxide state directory is not writable. |
| Chromium | Chromium reported Crashpad Mach registration, socket directory, and `ProcessSingleton` failures | `allowBrowserProcess` was already enabled. The failure is probably a sandbox-runtime defect or a Chromium profile-directory problem. |
| tmux server creation | Repeated `create window failed: fork failed: Operation not permitted` errors | Filesystem and Unix-socket permissions do not resolve this failure. Creating a tmux server inside the macOS Seatbelt sandbox is unreliable. |
| Harness API | Bash reported `Network access to "app.harness.io" is blocked` | This restriction appears intentional. The Harness MCP server supplies the approved access path. |
| AWS configuration | Commands could not read `~/.aws/config` | This restriction is intentional. AWS access must use `aws-sandy`. |

## Recommendations

### Permit Nix channel metadata reads

Add this narrow path to `filesystem.allowRead`:

```json
"~/.nix-defexpr"
```

This change resolves the repeated Nix `posix_stat` failures without permitting reads from the full home directory.

### Permit zoxide state writes

Add this path to `filesystem.allowWrite`:

```json
"~/Library/Application Support/zoxide"
```

This change permits zoxide to create its temporary database file. Do not make all of `~/Library/Application Support` writable.

### Keep the session temporary-directory solution

`modules/configs/pi-coding-agent/extensions/session-temp.ts` puts session temporary files under `/tmp/claude`. This location is writable inside the sandbox.

Because this solution is active, test whether the broad `"/var"` write entry is still necessary. Remove it if the sandbox works without it. The broad entry did not prevent the observed `/var/folders/...` failures.

### Refine Git metadata permissions

The current uncommitted entries solve real historical failures:

```json
"~/dev/*/.git",
"~/dev/*/.git/**"
```

These entries also permit writes to the Git metadata of every direct child repository under `~/dev`.

A safer long-term design is:

1. Run `git rev-parse --git-common-dir` when a session starts.
2. Add only the returned Git directory to the session sandbox configuration.
3. Keep dispatcher worktrees under `~/dev/agents/worktrees`.
4. Keep normal worktrunk worktrees inside the source repository.

Until dynamic configuration is available, the current wildcard entries are a practical compromise.

### Do not broaden Chromium permissions yet

The current sandbox-runtime implementation of `allowBrowserProcess` grants broad Mach, process information, IOKit, and shared-memory permissions. Additional global permissions would increase risk without a known benefit.

First, retest Chromium with the current sandbox-runtime version and a profile under `PI_SESSION_TEMP`:

```fish
chromium \
  --headless \
  --user-data-dir="$PI_SESSION_TEMP/chrome-profile" \
  --disable-crash-reporter \
  --no-first-run \
  --no-default-browser-check
```

If this command still fails, report the problem as a sandbox-runtime defect instead of adding broad filesystem or Mach permissions.

### Move tmux server creation outside sandboxed Bash

`allowAllUnixSockets` permits access to an existing tmux server. It does not make new tmux server creation reliable.

Use one of these designs:

- Start tmux from a Pi extension before the sandbox applies.
- Add a dedicated Pi tool that creates the tmux session outside sandboxed Bash.
- Reuse an existing tmux server instead of running `tmux -L ... new-session` in tests.

Additional filesystem permissions are unlikely to resolve the tmux failure.

### Keep intentional network restrictions

Do not add these domains to the Bash network allowlist:

- `app.harness.io`
- AWS service domains
- Anthropic API domains that use an approved proxy

Use the Harness MCP server and `aws-sandy`. These tools keep credentials and private service access outside general shell commands.

## Suggested immediate patch

The two low-risk additions are:

```diff
 "allowRead": [
   ".",
   "/nix",
   ...
+  "~/.nix-defexpr",
   "~/.nix-profile/**",
   ...
 ],
 "allowWrite": [
   ".",
   ...
+  "~/Library/Application Support/zoxide",
   "~/Library/Caches",
   ...
 ]
```

The existing uncommitted Git and dispatcher changes address most historical worktree failures.
