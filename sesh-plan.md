# sesh 2.28.0 — simplify the tmux/sesh setup

Consolidate on sesh's native picker TUI (matured in 2.27.0 → 2.28.0) and drop
the fzf-based and television-based session pickers.

## Why

sesh 2.28.0's built-in picker gained the features that previously justified
wrapping it in fzf/television:

- **Preview pane** (`[tui] preview`) — reuses the existing
  `default_session.preview_command`; toggle with `ctrl+o`.
- **Custom icons** (`show_icons`, per-session/wildcard `icon`).
- **Window names** in rows (`show_windows`).
- **Number-jump** — type `#` then `1`–`9`.
- **Session aliases** with optional auto-connect.
- **`--query` / `-q`** prefill flag.
- (2.27.0) Emacs nav keys (Ctrl-P/Ctrl-N), `sesh mkdir`, `sesh cache refresh`.

The upstream author "removed my fzf bindings and went all-in on the new picker."

Installed sesh is **2.26.2** (from pinned nixpkgs `b5aa0fbd`, 2026-06-29). The
`picker` subcommand exists there but lacks preview/icons/query/alias — hence
Step 0.

## Decisions

- **Consolidate on `sesh picker` everywhere** — both the tmux `bind s` popup and
  the shell `s` abbr use the native picker.
- **Remove the television `sesh` channel** — it is only referenced by the `s`
  abbr (and its own recursive kill action), so it becomes dead code.
- **Accept losing the in-picker `ctrl-k` kill action.** The native picker has no
  kill binding. Killing falls back to `wtclean`, tmux `bind X`
  (`tmux-kill-session`), or `tmux kill-session`.
- **No custom icon for the dolomite SSH session** — its
  `sesh.settings.session` entry in `home.nix` stays as-is.

## Open decision

- **Step 0 delivery mechanism** — scoped `sesh` overlay pinning 2.28.0 (lowest
  risk, given the deliberate ld64-workaround comment on the nixpkgs pin) **vs**
  bumping the `nixpkgs` flake input. TBD before implementing.

## Steps

### 0. sesh ≥ 2.28.0 (blocking)

Pinned nixpkgs ships 2.26.2. Either add a scoped `sesh` overlay (`buildGoModule`
with new `version`/`src`/`vendorHash`) or bump the `nixpkgs` input once it
carries 2.28.0. The home-manager `programs.sesh.settings` option is freeform
TOML, so all config below works without a home-manager bump.

### 1. `modules/shell.nix` — add `settings.tui`

```nix
settings = {
  default_session.preview_command = "eza …";   # unchanged, reused by the pane
  tui = {
    preview = true;
    show_icons = true;
    show_windows = true;
    preview_min_width = 80;   # so the pane still shows in the popup
    preview_border = "line";
  };
};
```

### 2. `modules/configs/tmux.nix` — `bind s` → native picker

```
unbind s
bind s display-popup -E -w 80% -h 80% "sesh picker -i"
```

Drops the `sesh list -i | fzf … | xargs sesh connect` pipeline (no `pkgs.fzf`
in this binding anymore). Popup enlarged from `-w 50 -h 18` to `80%` so the
preview pane has room.

### 3. Point the shell `s` abbr at the picker + remove the dead channel

- `modules/configs/fish.nix`: `s = "tv sesh --no-sort";` → `s = "sesh picker -i";`
- `modules/configs/television-channels.nix`: **delete the entire `sesh = { … }`
  block** (now unreferenced).

### 4. (skipped) No dolomite icon

Per decision — leave `home.nix` `sesh.settings.session` untouched.

### 5. Verify

- Rebuild (`home-manager switch` / rebuild alias); confirm `sesh version` ≥ 2.28.0.
- tmux prefix-`s` and shell `s` both open the native picker with eza preview +
  icons; `ctrl+o` toggles preview; `#` then a digit jumps; Enter connects.
- `bind a` (`sesh last`) and `tmux-kill-session` (uses `sesh last`) still work.

## Files touched

| File | Change |
|---|---|
| `flake.nix` (or an overlay) | sesh → 2.28.0 (Step 0) |
| `modules/shell.nix` | add `settings.tui` block |
| `modules/configs/tmux.nix` | `bind s` → `sesh picker -i` popup |
| `modules/configs/fish.nix` | `s` abbr → `sesh picker -i` |
| `modules/configs/television-channels.nix` | remove `sesh` channel block |
