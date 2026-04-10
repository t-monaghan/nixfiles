# Claude Code tmux session name hooks

Rename your tmux session and highlight it in bright yellow when Claude is waiting for permission or user input, then restore it when you send your next message.

## How it works

1. **`Notification` hook** (fires on `permission_prompt`) — saves the original session name, renames it to `* name *`
2. **`Stop` hook** (fires when Claude finishes responding) — also renames to `* name *` (Claude is now idle, waiting for input)
3. **`UserPromptSubmit` hook** (fires when you send a message) — restores the original session name
4. **`SessionEnd` hook** (fires when Claude exits) — restores the original session name so it isn't left renamed after the session ends

The original name is stashed in a tmux session-scoped environment variable (`CLAUDE_ORIGINAL_SESSION`) so the restore is reliable even if other session properties change in the meantime.

## 1. Add the hooks to your Claude settings

In `~/.claude/settings.json` (global) or `.claude/settings.json` (project), add a `hooks` key (or merge into your existing one):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then session=$(tmux display-message -p '#{session_name}'); case \"$session\" in \\*\\ *) ;; *) tmux set-environment -t \"$session\" CLAUDE_ORIGINAL_SESSION \"$session\" && tmux rename-session -t \"$session\" \"* $session *\";; esac; fi"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then session=$(tmux display-message -p '#{session_name}'); case \"$session\" in \\*\\ *) ;; *) tmux set-environment -t \"$session\" CLAUDE_ORIGINAL_SESSION \"$session\" && tmux rename-session -t \"$session\" \"* $session *\";; esac; fi"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then session=$(tmux display-message -p '#{session_name}'); original=$(tmux show-environment -t \"$session\" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n \"$original\" ]; then tmux rename-session -t \"$session\" \"$original\" && tmux set-environment -t \"$original\" -u CLAUDE_ORIGINAL_SESSION; fi; fi"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then session=$(tmux display-message -p '#{session_name}'); original=$(tmux show-environment -t \"$session\" CLAUDE_ORIGINAL_SESSION 2>/dev/null | sed 's/^[^=]*=//'); if [ -n \"$original\" ]; then tmux rename-session -t \"$session\" \"$original\" && tmux set-environment -t \"$original\" -u CLAUDE_ORIGINAL_SESSION; fi; fi"
          }
        ]
      }
    ]
  }
}
```

That's all you need for the rename behaviour. The `$TMUX` check means the hooks are no-ops outside tmux.

### What the hooks do step by step

**Notification + Stop hooks (rename):**
1. Gets the current session name via `tmux display-message -p '#{session_name}'`
2. Skips if already renamed (name starts with `*`)
3. Stores the original name: `tmux set-environment -t "$session" CLAUDE_ORIGINAL_SESSION "$session"`
4. Renames the session: `tmux rename-session -t "$session" "* $session *"`

**UserPromptSubmit hook (restore):**
1. Gets the current (renamed) session name
2. Reads the stashed original: `tmux show-environment -t "$session" CLAUDE_ORIGINAL_SESSION`
3. Renames back to the original
4. Cleans up the env var: `tmux set-environment -t "$original" -u CLAUDE_ORIGINAL_SESSION`

**SessionEnd hook (restore on exit):**
Same restore logic as UserPromptSubmit — ensures the session name is cleaned up when Claude exits, even if the user never sends another prompt (e.g. Ctrl-C or `/exit` while Claude is idle).

## 2. (Optional) Add bright yellow styling in your tmux config

The rename alone is enough to see `* myproject *` in your session list. If you also want the name rendered in bright yellow, you need to update your tmux config wherever `#{session_name}` appears.

The idea: use tmux's `#{m:}` (match) conditional to check if the session name matches the `* ... *` pattern, and if so, wrap it in a `#[fg=brightyellow]` style.

### Status bar example

If your status bar shows the session name like this:

```tmux
set -g status-left ' #{session_name} '
```

Replace it with:

```tmux
set -g status-left ' #{?#{m:*\* *,#{session_name}},#[fg=brightyellow]#{session_name}#[fg=default],#{session_name}} '
```

### Breaking down the conditional

```
#{?#{m:*\* *,#{session_name}},  <-- if session_name matches glob "* *"
  #[fg=brightyellow]             <-- apply bright yellow
  #{session_name}                <-- print the name
  #[fg=default],                 <-- reset colour (true branch end)
  #{session_name}                <-- else: print name normally
}
```

The `*\* *` glob pattern means: anything, then a literal `*`, a space, then anything. This matches `* myproject *` but not `myproject`. The `\*` is needed because `*` is also the tmux glob wildcard — the backslash makes it literal.

### Window list example

If you use `automatic-rename` or have `#{session_name}` in `window-status-format`:

```tmux
set -g window-status-format ' #{?#{m:*\* *,#{session_name}},#[fg=brightyellow]#{session_name}#[default],#{session_name}} '
```

### Pane border example

If you show session info in pane borders:

```tmux
set -g pane-border-format ' #{?#{m:*\* *,#{session_name}},#[fg=brightyellow]#{session_name}#[default],#{session_name}} '
```

### General rule

Anywhere you have `#{session_name}` and want it to turn yellow during permission prompts, wrap it with:

```
#{?#{m:*\* *,#{session_name}},#[fg=brightyellow]#{session_name}#[default],#{session_name}}
```

If you don't add any tmux styling, the `* name *` rename still works — you just won't get the colour change.

## Customisation

**Change the rename pattern** — edit the rename hooks and the restore hook to use a different prefix/suffix (e.g. `[!] name` instead of `* name *`). Update the tmux `#{m:}` glob to match your new pattern.

**Change the colour** — replace `brightyellow` with any tmux colour (`red`, `colour214`, `#ffaa00`, etc.).

**Trigger on fewer events** — if you only want the highlight during permission prompts (not when idle), remove the `Stop` hook and move the restore command back to `Stop` instead of `UserPromptSubmit`.
