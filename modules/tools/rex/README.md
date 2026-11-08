# Rex shortcuts

On both macOS laptops, Home Manager uses the Rex snapshot input to install the Rex CLI, terminfo entries, and SSH guard. Home Manager installs `init.lua`, `history.lua`, and `dolomite.lua` in `~/.config/rex/`. Install the Rex app separately; the Rex app runs the macOS server. The Home Manager Rex server service stays disabled.

All shortcuts are direct: hold **Cmd-Shift** and press the key in the table. No prefix is required.

| Key | Action |
| --- | --- |
| `h` / `j` / `k` / `l` | Focus pane left / down / up / right |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Resize pane in that direction by 5 percent |
| `d` / `Ctrl-d` | Split right / down |
| `z` | Toggle pane zoom |
| `x` | Close pane |
| `c` | New tab |
| `n` / `p` | Next / previous tab |
| `1`–`9` | Select tab |
| `,` | Rename tab |
| `s` | Session picker |
| `a` | Toggle between the two most recently visited sessions |
| `]` / `[` | Next / previous session in Rex's session order |
| `Ctrl-n` | New session |
| `Ctrl-s` | Rename session |
| `r` | Reload Rex configuration |

These shortcuts do not conflict with the configured OmniWM shortcuts in `modules/tools/omniwm.nix`. OmniWM uses Option for window focus and Control-Option for column selection. Rex uses Cmd-Shift, with Control added for resize and secondary actions. This configuration replaces Rex defaults on the same keys. Shortcuts set in the Rex app override this configuration. Existing arrow-key shortcuts remain available.

## Dolomite session

Run this after Home Manager activation:

```fish
rex do ~/.config/rex/dolomite.lua
```

The script uses the Rex host named `dolomite`. Each run creates a new session with one tab and two equal-width panes: `/home/tom/nixfiles` on the left and `/home/tom/nxp` on the right. Rex assigns a unique session name. The script then asks the Rex app to select the session.

Override the session name or directories when needed:

```fish
rex do ~/.config/rex/dolomite.lua name=work nixfiles=/home/tom/dev/nixfiles nxp=/home/tom/dev/nxp
```

Use `-C CLIENT` before `do` if multiple Rex apps are connected. Add `select=false` after the script path to create the session without selecting it. The script returns the new session and pane IDs. If selection fails, the error includes the created session ID; do not rerun the script unless you want another session.

The directories must exist on dolomite. Rex starts in the account's home directory if a supplied directory does not exist.

## Recent-session history

On desktop macOS hosts, Home Manager starts the `rex-session-history` LaunchAgent. It runs `track-sessions.lua` with the Rex CLI from the pinned flake input. It retries when Rex is not running; it does not start or restart Rex Server.

The process records session attachments for each Rex app client in `$XDG_STATE_HOME/rex/session-history.json`, or `~/.local/state/rex/session-history.json`. Normal session changes, including picker and mouse selection, attach the app to the selected session. The `last_session` action selects the most recent recorded session other than the current session. Closed sessions are skipped. History survives configuration reloads and process restarts.

Rex does not expose an active-session event. Focus changes between already-attached sessions in multiple Rex app windows cannot be tracked with attachment events. The toggle is intended for normal single-window session switching on one server. The LaunchAgent does not track remote servers or run on Linux.

After Home Manager activation, press **Cmd-Shift-r** to reload Rex. Visit another session after the LaunchAgent starts to establish recent-session history.

Check `init.lua` with Rex's `config check` command. Run `modules/tools/rex.test.mjs` with Node's test runner to check history, direct shortcuts, and OmniWM conflicts. The tests require Rex and `PI_SESSION_TEMP`.
