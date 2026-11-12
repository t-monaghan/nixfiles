# Rex shortcuts

On both macOS laptops, Home Manager uses the Rex snapshot input to install the Rex CLI, terminfo entries, and SSH guard. Home Manager installs the Rex Lua configuration and session scripts in `~/.config/rex/`. Install the Rex app separately; the Rex app runs the macOS server. The Home Manager Rex server service stays disabled.

All shortcuts are direct. Hold **Cmd-Shift** for the keys in the first table. The pickers, shortcuts popup, and session-creation reload use **Alt-Shift**, as shown in the second table. No prefix is required. Alt is the Option key on macOS.

| Key | Action |
| --- | --- |
| `h` / `j` / `k` / `l` | Focus pane left / down / up / right |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Resize pane in that direction by 5 percent |
| `d` / `Ctrl-d` | Split right / down |
| `z` | Toggle pane zoom |
| `x` | Close pane |
| `c` | New tab |
| `n` | Next tab |
| `1`–`9` | Select tab |
| `,` | Rename tab |
| `s` | Existing Rex session picker |
| `a` | Toggle between the two most recently visited sessions |
| `]` / `[` | Next / previous session in Rex's session order |
| `Ctrl-n` | New session |
| `r` | Reload Rex configuration without creating sessions |

| Shortcut | Action |
| --- | --- |
| **Cmd-Shift-p** | Rex's native command palette (default binding) |
| **Cmd-r** | Rename session |
| **Cmd-w** | Close the Rex app window, not the selected tab |
| **Alt-Shift-/** (**Alt-?**) | Show configured Rex bindings in a searchable popup; **Esc** closes it |
| **Alt-Shift-o** | Create missing configured sessions, then open Rex's session picker |
| **Alt-Shift-p** | Repository, then worktree / PR picker |
| **Ctrl-Alt-Shift-w** | Close current PR / worktree session |
| **Alt-Shift-c** | Ensure local sessions and reload Rex configuration |

**Alt-Shift-r** is reserved for OmniWM's `raiseAllFloatingWindows` action. OmniWM's `toggleOverview` shortcut is unassigned so Rex can use **Alt-Shift-o**.

These shortcuts do not conflict with the configured OmniWM shortcuts in `modules/tools/omniwm.nix`. OmniWM uses Option for window focus and Control-Option for column selection. Rex uses Cmd-Shift, with Control added for resize and secondary actions, except for Cmd-r to rename the session, Cmd-w to close the app window, Alt-Shift-o/p for the pickers, Alt-Shift-/ for the shortcuts popup, Alt-Shift-c to reload configuration, and Ctrl-Alt-Shift-w to close a PR / worktree session. OmniWM uses Alt-Shift-w, so Rex adds Control for its close action. This configuration replaces Rex defaults on the same keys. Shortcuts set in the Rex app override this configuration. Existing arrow-key shortcuts remain available.

The shortcuts popup reads the current server configuration with `rex keymap`. It lists configured bindings and their arguments, not Rex defaults or shortcuts set in the app. It does not execute bindings. Press **Esc** to close the popup and return to the terminal.

## Configured sessions

Use **Cmd-Shift-s** to navigate with Rex's native session picker. **Alt-Shift-o** creates any missing configured sessions, then opens the same picker. Existing sessions keep their terminals and running programs.

Home Manager generates `session-settings.lua` from `programs.sesh.settings.session` in `modules/tools/sesh.nix`. `modules/tools/rex.nix` excludes `dolomite` and sets the Rex session order:

| Session | Directory | Startup command |
| --- | --- | --- |
| `hud` | `~/dev` | Configured `hud-session` executable |
| `notes` | `~/notes` | `nvim ~/notes/notes.md && exit` |
| `nixfiles` | `~/dev/nixfiles/` | Interactive shell |

On desktop macOS hosts, the existing `rex-session-history` LaunchAgent creates missing local sessions when it connects to Rex. It retries while Rex is unavailable and connects again after a server restart. Rex does not permit server API calls during config loading, so startup session creation runs through this service instead. **Alt-Shift-c** also creates missing local sessions before reloading the configuration.

After session creation or reuse, the configured sessions appear first in the order above. Other sessions retain their relative order. New PR sessions are appended. Session ordering applies to every client on the local server.

Startup commands run only when a session is created. If multiple sessions have the same configured name, rename one before trying again. Closing Notes or HUD does not immediately recreate its session; startup, reload, or **Alt-Shift-o** can create it again.

Apply Home Manager, then reload Rex once with its command palette to register the new actions. Apply Home Manager again after changing the Sesh session definitions. Session creation reads the generated settings, not the Sesh cache.

## Worktree / PR picker

Press **Alt-Shift-p**, select a repository, then select an existing worktree or an open GitHub PR. The focused terminal's current repository appears first, followed by zoxide entries below `~/dev`. Duplicate paths appear only once. Repository labels omit the `$HOME/dev/` prefix, but selections retain the full path. Paths outside `$HOME/dev/` remain unchanged. Press **Enter** to select the first entry, or type to filter either list. **Escape** / **Ctrl-C** cancels without opening a session.

Rex reads the local foreground process's directory before opening the picker. Subdirectories resolve to their Git worktree root. If no directory is available, the directory is not a Git repository, or the foreground process is SSH or Mosh, the picker shows the normal zoxide list. The current repository does not need a zoxide entry and can be outside `~/dev`. When opened from an existing worktree, session names still use the main repository's name.

An existing worktree opens in a Rex session. Selecting an open PR without a worktree first calls the configured `wt` fish wrapper to create the worktree. The picker selects an existing Rex session with the same name instead of creating another one.

Session names use `repo #123` when a PR number is available, or `repo: branch` otherwise. Existing worktree directories stay unchanged. The `wt` wrapper already uses `.worktrees/pr-123` for new worktrees when a PR number is available; this change does not rename Git branches or relocate worktrees.

The picker reads PR numbers from `pr-123` directory names first. For branch-named directories, it matches against the repository's 100 most recent GitHub PRs, including closed and merged PRs. Only open PRs appear as candidates for new worktrees. If GitHub is unavailable, existing worktrees remain available; branch-named directories use branch labels. Other repositories need a zoxide entry to appear in the first picker.

This picker needs Rex **Remote Control** enabled. Worktrunk hooks run normally when creating a worktree. Each worktree opens as a separate Rex session, not a tmux session.

**Ctrl-Alt-Shift-w** destroys the current PR / worktree session and closes all its terminals. It does not delete the worktree or close the GitHub PR. The action refuses configured sessions and labels outside the `repo #123` / `repo: branch` formats. Use Rex's normal close action for other sessions.

## Recent-session history

On desktop macOS hosts, Home Manager starts the `rex-session-history` LaunchAgent. It runs `track-sessions.lua` with the Rex CLI from the pinned flake input. It retries when Rex is not running; it does not start or restart Rex Server.

The process records session attachments for each Rex app client in `$XDG_STATE_HOME/rex/session-history.json`, or `~/.local/state/rex/session-history.json`. Normal session changes, including picker and mouse selection, attach the app to the selected session. The `last_session` action selects the most recent recorded session other than the current session. Closed sessions are skipped. History survives configuration reloads and process restarts.

Rex does not expose an active-session event. Focus changes between already-attached sessions in multiple Rex app windows cannot be tracked with attachment events. The toggle is intended for normal single-window session switching on one server. The LaunchAgent does not track remote servers or run on Linux.

After Home Manager activation, press **Cmd-Shift-r** to reload Rex configuration, or **Alt-Shift-c** to also create missing local sessions. Visit another session after the LaunchAgent starts to establish recent-session history.

Check `init.lua` with Rex's `config check` command. Run `modules/tools/rex.test.mjs` and `modules/tools/rex/*.test.mjs` with Node's test runner to check history, direct shortcuts, OmniWM conflicts, session creation and reuse, PR labels, and picker cancellation. The tests require Rex and `PI_SESSION_TEMP`.
