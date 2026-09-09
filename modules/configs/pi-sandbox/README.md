# Vendored pi sandbox

Source: [jay-aye-see-kay/.pi](https://github.com/jay-aye-see-kay/.pi/tree/b9bd5741048c7cbf493d9a89dc767ad107a047ef/agent/extensions/sandbox)

Commit: `b9bd5741048c7cbf493d9a89dc767ad107a047ef`

## Installation

On macOS, Home Manager copies this directory to
`~/.local/share/pi/extensions/sandbox` and runs `npm ci --include=dev` there.
The copy is writable so npm can install dependencies and apply the runtime patch.
Installation repeats when the source or Node package changes. Pi loads this
copy through its package settings. Dolomite keeps `npm:pi-sandbox`.

Run `./scripts/switch work` or `./scripts/switch personal`, then start a new pi
process. The first activation needs access to the npm registry.

## Policy

The global policy remains in
`modules/configs/pi-coding-agent/sandbox.json`. Project overrides still load from
`.pi/sandbox.json`.

The upstream runtime patch removes hardcoded write restrictions. The configured
`allowWrite` and `denyWrite` lists control write access instead. This includes
write access to Git hooks and executable configuration where the policy permits
it. No additional write protection rules are added here.

Bash commands use the OS sandbox. The extension checks read, write, and edit paths
separately. MCP tools, other extensions, and the built-in grep/find/ls tools are
outside these checks.

`/sandbox` shows the current policy. `/sandbox prompt` disables the OS sandbox
and asks before each covered operation. `/sandbox enable` returns to sandbox mode.

## Local changes

- Permission prompts offer session allow, session deny, and deny once only.
- Removed config writers and project/global grant options. Home Manager owns the
  global policy file. Add permanent permissions to the policy in this repository.

Grants and denials do not survive a new session or extension reload. Other
extension behavior, including its initialization failure handling, is unchanged
from upstream. If initialization fails, upstream reports an error but can run
commands without the OS sandbox; check the runtime status before use.

## Updates

Copy `index.ts`, `package.json`, `package-lock.json`, and `patches/` from a reviewed
upstream commit. Reapply the session-only changes and update the commit above.
Keep the lockfile and runtime patch together: the patch targets sandbox-runtime
0.0.74. `patch-package` is a development dependency, so installation must include
development dependencies and permit the postinstall script.
