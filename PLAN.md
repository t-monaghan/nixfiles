# Plan: Standalone home-manager flake (macOS, zsh, no nix-darwin)

A starter plan for a fresh, per-user Nix setup on macOS. Built on **standalone
home-manager** — no nix-darwin, no root, no system layer.

> This document is self-contained. Each section maps to one decision; the build
> order at the end is the suggested implementation sequence.

---

## 0. Guiding principle: standalone home-manager, **not** nix-darwin

Everything is built on `home-manager.lib.homeManagerConfiguration` — a per-user
config with **no** system/root layer. This is a deliberate choice.

- **Why:** no `darwin-rebuild`, no system activation, no root, no system-state
  version to babysit. You manage *your user's* tools and dotfiles only.
- **Cost of avoiding nix-darwin:** anything that genuinely needs root
  (system-wide daemons, `/etc`, Homebrew orchestration) isn't available. In
  practice almost everything is user-scoped, and the few macOS *app preferences*
  we need are handled with `defaults write` in a home-manager **activation
  script** (§7) — no nix-darwin required.
- **Switch command** is therefore `home-manager switch --flake .#<profile>`,
  never `darwin-rebuild`.

---

## 1. Repository skeleton

```
flake.nix              # inputs + mkHost helper + homeConfigurations (personal/work)
flake.lock
lib/
  mkHost.nix           # one function that builds a homeManagerConfiguration
hosts/
  personal.nix         # per-machine: username, homeDirectory, which options to enable
  work.nix
modules/
  default.nix          # imports home.nix + work module(s)
  home.nix             # THIN: auto-imports every top-level configs/*.nix (see §3)
  configs/
    <app>.nix          # one file per app, each a HM module (git.nix, zsh.nix, ...)
    mcp.nix            # the shared MCP server set (§4)
    nix-search.nix     # package/option search (§11)
    lib/               # NON-modules: colour/font palettes, data (NOT auto-imported)
      colours.nix
    pkgs/              # NON-modules: callPackage derivations (NOT auto-imported)
      notunes.nix
  work/<company>/
    options.nix        # declares nixfiles.work.<company>.enable
    home.nix           # work tools, gated by lib.mkIf
scripts/
  switch               # wrapper around `home-manager switch`
  news                 # home-manager news
README.md              # include the §9 writable-config doc + §11 module-first rule
```

Two deliberate upgrades baked in from the start: a **thin `home.nix`** (§3) and a
**dedicated `mcp.nix`** (§4).

---

## 2. Personal / work split profiles

Two outputs built by one helper.

**`lib/mkHost.nix`:**

```nix
# inputs come from flake.nix via `import ./lib/mkHost.nix inputs`
{ home-manager, nixpkgs, mac-app-util, sandy, imds-broker, ... }:
{ name, username, system ? "aarch64-darwin", extraModules ? [] }:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        sandy = sandy.packages.${final.system}.default;
        imds-broker = imds-broker.packages.${final.system}.default;
      })
    ];
  };
  modules = [
    mac-app-util.homeManagerModules.default   # §5
    ../hosts/${name}.nix
  ] ++ extraModules;
  extraSpecialArgs = { inherit username; };
}
```

**`flake.nix` (shape):**

```nix
{
  description = "<friend>'s home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";          # §5

    imds-broker.url = "github:<you>/imds-broker";             # §6
    imds-broker.inputs.nixpkgs.follows = "nixpkgs";
    sandy.url = "github:<you>/sandy";                         # §6
    sandy.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { ... }:
    let mkHost = import ./lib/mkHost.nix inputs;
    in {
      homeConfigurations = {
        personal = mkHost { name = "personal"; username = "alice"; };
        work     = mkHost { name = "work";     username = "alice.smith"; };
      };
    };
}
```

**The split itself** is an *optional module gated by an enable option*, so work
tooling never leaks onto the personal machine:

```nix
# modules/work/acme/options.nix
{ lib, ... }: {
  options.nixfiles.work.acme.enable = lib.mkEnableOption "Acme work tools";
}
```

```nix
# modules/work/acme/home.nix
{ config, lib, pkgs, ... }:
lib.mkIf config.nixfiles.work.acme.enable {
  home.packages = with pkgs; [ jira-cli-go buildkite-cli ];
  programs.awscli.enable = true;
  # work-only MCP servers (§4), shell aliases/functions (§12), etc.
}
```

```nix
# hosts/work.nix
{ username, ... }: {
  imports = [ ../modules ];
  home = { inherit username; homeDirectory = "/Users/${username}"; };
  nixfiles.work.acme.enable = true;     # <- the only line that differs
}
# hosts/personal.nix leaves the option off (defaults false)
```

> Keep **everything company-specific** (package names, internal MCP URLs,
> repo-clone helpers) inside `modules/work/<company>/` so the personal half can
> be shared without leaking work details.

---

## 3. Per-app config files — a simpler way to find config

**Rule:** one app = one file, named after the app. "Where's my Zed config?" is
always answered by `modules/configs/zed.nix`. Avoid the one-giant-`home.nix`
trap.

**`home.nix` auto-imports every top-level `configs/*.nix`** — so adding a new app
is just "drop a file in `configs/`", no import line to maintain:

```nix
# modules/home.nix
{ lib, ... }:
let
  configDir = ./configs;
  # Only TOP-LEVEL *.nix files (non-recursive) — each must be a HM module.
  entries = builtins.readDir configDir;
  modules = lib.mapAttrsToList (name: _: configDir + "/${name}") (
    lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name
    ) entries
  );
in {
  imports = modules;
}
```

Each `modules/configs/<app>.nix` must be a normal home-manager module
(`{ pkgs, lib, config, ... }: { programs.foo = { ... }; }`) so a tool's package +
settings live together and the file is safely auto-importable.

**Why non-recursive + top-level only?** Some `.nix` files are *not* modules and
would crash the import if picked up:

- **`callPackage` derivations** (e.g. `notunes.nix`, §7) take
  `{ lib, stdenvNoCC, ... }`, not module args.
- **Plain attrsets** meant to be `import`-ed with args (colour/font palettes).

Keep those out of the auto-import path by putting them in **subdirectories**,
which `readDir` (non-recursive) skips:

- `configs/lib/colours.nix`, `configs/lib/fonts.nix` — palettes; an app file
  pulls one in with `import ./lib/colours.nix`.
- `configs/pkgs/notunes.nix` — derivations; consumed via
  `pkgs.callPackage ./pkgs/notunes.nix {}` from within an app module.

> The convention to write down: **a top-level `configs/*.nix` is always a
> home-manager module; anything else lives in a subdirectory.** That keeps the
> auto-import total and predictable — if it's at the top level, it's loaded.

---

## 4. Global MCP config shared across agents

Define MCP servers **once** in `programs.mcp.servers` → home-manager writes
`~/.config/mcp/mcp.json`, and **every agent module inherits it** via
`enableMcpIntegration`.

```nix
# modules/configs/mcp.nix
{ ... }: {
  programs.mcp = {
    enable = true;
    servers = {
      context7.url = "https://mcp.context7.com/mcp";
      # ...personal/global servers here
    };
  };

  # Each agent merges programs.mcp.servers in:
  programs.claude-code.enableMcpIntegration = true;
  programs.opencode.enableMcpIntegration    = true;
  programs.codex.enableMcpIntegration       = true;
  # zed-editor, github-copilot-cli, antigravity-cli also expose this option.
}
```

- **pi** picks up the same `~/.config/mcp/mcp.json` via the `pi-mcp-adapter`
  package (listed in pi's `settings.json` `packages`), so pi shares the exact
  same set without a separate definition.
- **Work-only servers** (internal Atlassian/Buildkite/etc.) go in
  `modules/work/<company>/home.nix` as `programs.mcp.servers.<name> = { ... };`.
  home-manager merges them on top, so the work profile gets personal **+** work
  servers and personal gets only personal ones.
- **File-backed secrets** are supported: `env.TOKEN.file = "/run/secrets/...";`
  (sops-nix / systemd-creds friendly) — so tokens aren't baked into the store.

Confirmed in the home-manager source: `claude-code`, `opencode`, `codex`,
`zed-editor`, `github-copilot-cli`, and `antigravity-cli` all read
`config.programs.mcp.servers` when `enableMcpIntegration` is on. Define once,
used everywhere.

---

## 5. `mac-app-util` — GUI apps visible to Spotlight / Launchpad

Nix-installed `.app`s land in the nix store and **don't show up in Spotlight or
Launchpad** by default. `mac-app-util` creates the right trampolines/aliases so
they do.

- **Input:** `mac-app-util.url = "github:hraban/mac-app-util";`
- **Wire-up:** add `mac-app-util.homeManagerModules.default` to the `modules`
  list in `mkHost` (shown in §2). Standalone home-manager → use the
  **home-manager** module, not the darwin one.
- It then automatically handles any GUI app installed via `home.packages`
  (editors, Obsidian, BetterDisplay, custom `.app`s, …).

---

## 6. `imds-broker` + `sandy`

Both are flakes pulled from GitHub and surfaced as `pkgs.*` via an overlay (see
`mkHost`, §2).

```nix
# flake.nix inputs
imds-broker.url = "github:<you>/imds-broker";
imds-broker.inputs.nixpkgs.follows = "nixpkgs";
sandy.url        = "github:<you>/sandy";
sandy.inputs.nixpkgs.follows = "nixpkgs";
```

Usage:

- **Packages:** add `sandy` and `imds-broker` to `home.packages`.
- **sandy config:**
  `xdg.configFile."sandy/config.json".text = builtins.toJSON { backend = "docker"; };`
- **imds as an MCP server** (work profile): a
  `programs.mcp.servers.imds-broker = { command = "imds-broker"; args = [ "mcp" "--profile-filter" "..." ]; };`
  so it flows to all agents via §4.
- If using pi, the sandbox uses the `pi-sandbox` package; keep that in pi's
  `settings.json` `packages`.

> `inputs.nixpkgs.follows = "nixpkgs"` on each keeps the closure small and avoids
> multiple nixpkgs copies.

---

## 7. macOS app preferences without nix-darwin (activation `defaults write`)

Manage "Mac app" behaviour while avoiding nix-darwin: a home-manager
**activation script** runs `defaults write` for app preferences, and a tiny
derivation packages a `.app` from a GitHub release when it isn't in nixpkgs.

```nix
# in some configs/*.nix — example: the Mos scroll utility
home.activation.mosDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  /usr/bin/defaults write com.caldis.Mos reverse 1
  /usr/bin/defaults write com.caldis.Mos speed 2.50
  # ...
'';
```

Packaging a release `.app` that isn't in nixpkgs (pattern):

```nix
# modules/configs/pkgs/notunes.nix  (a derivation, NOT a module — lives in pkgs/)
{ lib, stdenvNoCC, fetchurl, unzip }:
stdenvNoCC.mkDerivation rec {
  pname = "notunes";
  version = "3.5";
  src = fetchurl {
    url = "https://github.com/tombonez/noTunes/releases/download/v${version}/noTunes-${version}.zip";
    hash = "sha256-...";   # nix will tell you the right hash on first build
  };
  sourceRoot = ".";
  nativeBuildInputs = [ unzip ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r noTunes.app $out/Applications/noTunes.app
    runHook postInstall
  '';
  meta.platforms = lib.platforms.darwin;
}
```

Add it from within an app module with
`(pkgs.callPackage ./pkgs/notunes.nix {})` in `home.packages`. It lives under
`configs/pkgs/` precisely so the §3 auto-import skips it. Combined with §5,
packaged apps show up in Spotlight and get their prefs set — all user-level, no
root.

---

## 8. Switch scripts

Thin wrappers so the friend doesn't memorise the flake invocation, and so the
very first run works *before* home-manager exists.

```bash
# scripts/switch
#!/usr/bin/env bash
if ! command -v home-manager &>/dev/null; then
  nix shell nixpkgs#home-manager --command home-manager switch --flake .#"$1"
else
  home-manager switch --flake .#"$1"
fi
```

```bash
# scripts/news
#!/usr/bin/env bash
nix run home-manager -- news --flake .#"$@"
```

Usage: `./scripts/switch personal` or `./scripts/switch work`. These are plain
bash and work regardless of login shell.

---

## 9. Writable, git-tracked config (the Zed pattern)

**The problem:** home-manager links config into the **nix store, which is
read-only**. For apps whose settings you declare in Nix
(`programs.zed-editor.userSettings = { ... }`), that's fine — but the *app itself
can't write changes* (toggling a setting in the UI, an app rewriting its own
file). Every tweak must round-trip through Nix + a rebuild.

**The pattern:** use `config.lib.file.mkOutOfStoreSymlink` to point the app's
config path at a **mutable file in your git-tracked checkout** instead of the
store:

```nix
# Make ~/.config/zed/settings.json a symlink to the live repo file.
home.file.".config/zed/settings.json".source =
  config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/dev/<repo>/modules/configs/zed/settings.json";
```

Now:

- The app **writes through the symlink into your repo working tree** → edits are
  immediately live, no rebuild.
- Because the target is a **committed file**, every change is `git diff`-able and
  ends up in **git history** — the same workflow as editing the file directly,
  but the editor manages it.
- The file stays as real JSON/TOML the app understands — not Nix.

**Caveats to document:**

1. **No longer purely reproducible** for that file — a fresh machine gets
   whatever is committed, but the app can drift it until you commit again. That's
   the trade-off you're opting into on purpose.
2. **Path must be an absolute path to the checkout** (`mkOutOfStoreSymlink`
   refuses store paths). Standardise on one location (e.g. `~/dev/<repo>`).
3. **Atomic-save apps can clobber the symlink.** Apps that save by "write temp
   file → rename over the target" replace the *symlink* with a plain file,
   breaking the link (the next switch restores it). Apps that edit in place are
   fine. Note which apps are safe.
4. **The target file must already exist** in the repo before the first switch.

**Rule of thumb:** declarative `userSettings`/`settings` for things you rarely
touch and want reproducible; `mkOutOfStoreSymlink` for "I tweak this live and
want it tracked" files. Don't mix both for the same file.

---

## 10. Nix search — discover packages **and** home-manager options

`nix-search-tv` indexed over **both `nixpkgs` and `home-manager`**. The
home-manager index is the important half: it's how you discover *which
`programs.*` modules and options exist* — which feeds the module-first rule
(§11). Let the module configure television for you — don't hand-roll a channel.

```nix
# modules/configs/nix-search.nix
{ ... }: {
  programs.television.enable = true;          # the only reason TV exists here

  programs.nix-search-tv = {
    enable = true;
    settings.indexes = [ "nixpkgs" "home-manager" ];   # search packages + HM options
    # enableTelevisionIntegration defaults to programs.television.enable (= true),
    # which auto-creates programs.television.channels.nix-search-tv —
    # no manual channel needed.
  };
}
```

Default keybindings the module wires up (macOS): `alt-s` open source, `alt-o`
homepage, `alt-r` `nix run` it, `alt-i` `nix shell` it. Override
`programs.television.channels.nix-search-tv` later only if you ever want to.

**Even-lighter alternative (no television at all)** — if the friend would rather
not pull in a TUI just for search, use fzf (likely already present):

```nix
programs.nix-search-tv.enable = true;   # package only, integration off (no TV)
programs.zsh.shellAliases.nixsearch =
  "nix-search-tv print | fzf --preview 'nix-search-tv preview {}'";
```

Pick one: television channel (richer, module does it for you) **or** the fzf
one-liner (no extra TUI).

**CLI equivalents worth noting:** `nix search nixpkgs <term>` for packages, and
the home-manager options search site (`home-manager-options.extranix.com`) for
options.

> Gotcha: `nix-search-tv` only reads config from `XDG_CONFIG_HOME`, which can be
> unset on macOS shells. If invoking it manually, prefix with
> `XDG_CONFIG_HOME=$HOME/.config`.

---

## 11. Prefer a home-manager **module** over a bare package

**Rule:** when a tool has a `programs.<name>` (or `services.<name>`)
home-manager module, enable *that* instead of just dropping the binary into
`home.packages`.

```nix
# Prefer this — module: binary + config + integration, all declarative
programs.git = {
  enable = true;
  settings.user.name = "Alice";
  ignores = [ ".DS_Store" ];
};

# Over this — package only: you get the binary, but config drifts into
# hand-edited dotfiles outside of Nix
home.packages = [ pkgs.git ];
```

**Why the module is better:**

- **Config travels with the install** — settings live in the same declarative
  file, version-controlled, reproducible. No hidden hand-edited dotfiles.
- **Integrations for free** — modules wire up shell integration (§12),
  `enable*Integration` hooks (e.g. `enableMcpIntegration` in §4 only exists
  *because* these are modules), completions, themes, services on demand.
- **Discoverable & type-checked** — options are searchable (§10) and validated at
  build time; a typo'd option fails the switch instead of silently doing nothing.
- **One source of truth** — package and config never drift apart.

**When a bare `home.packages` entry is fine (or necessary):**

1. **No module exists** — most CLIs (`tree`, `eza`, `jq`, `hyperfine`,
   `shellcheck`, formatters/linters) have none; a package entry is correct.
2. **GUI apps** — Obsidian, BetterDisplay, custom `.app` derivations (§7):
   package-only, with `mac-app-util` (§5) making them visible.
3. **You don't want the module's config surface** — sometimes you just need the
   binary and prefer to manage config another way (e.g. the writable-symlink
   pattern in §9). A deliberate choice, not the default.
4. **Module exists but is behind/buggy** — pin the package and configure
   manually until the module catches up.

**Decision checklist (put in the README):**

> 1. Search `home-manager` options (§10) for `programs.<tool>` / `services.<tool>`.
> 2. If it exists → `programs.<tool>.enable = true;` and configure via its options.
> 3. If not, or you explicitly don't want its config → add `pkgs.<tool>` to `home.packages`.
> 4. Never add the package **and** also hand-maintain its dotfile when a module
>    would manage both.

---

## 12. Shell: zsh

This setup uses **zsh** via the `programs.zsh` module. The key fact:
**zsh integration is automatic**, so this layer is short.

### The integration model (don't fight it)

- `home.shell.enableShellIntegration` defaults to **`true`** →
  `home.shell.enableZshIntegration` defaults to true → every tool's own
  `enableZshIntegration` defaults to that.
- **Therefore: once `programs.zsh.enable = true`, starship, zoxide, atuin,
  direnv, fzf, etc. all inject themselves into zsh automatically.** You do
  **not** write `enableZshIntegration = true` anywhere.
- You only ever *touch* `enableZshIntegration` to **turn one off** (e.g.
  `programs.fzf.enableZshIntegration = false;`).

### The module

```nix
# modules/configs/zsh.nix
{ ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -l";
      gs = "git status";
    };
    sessionVariables = { EDITOR = "nvim"; };

    history = {
      size = 100000;
      ignoreDups = true;
      share = true;
    };

    # Free-form init. Use initContent (NOT the deprecated initExtra).
    # Order anchors: lib.mkBefore/500 = early (old initExtraFirst);
    # 550 = before compinit; 1000/default = general (old initExtra).
    initContent = ''
      bindkey -v   # example: vi mode
    '';
  };
}
```

Notes (verified against the current module):

- **`initContent`** is the current option; `initExtra` / `initExtraFirst` /
  `initExtraBeforeCompInit` are renamed/deprecated. Wrap ordered chunks in
  `lib.mkOrder` / `lib.mkBefore` / `lib.mkAfter` if ordering matters.
- For Oh-My-Zsh there's `programs.zsh.oh-my-zsh = { enable = true; plugins = [...]; theme = "..."; };`
  — but with starship + autosuggestion + syntax-highlighting declared, you
  probably don't need OMZ at all.
- For fish-style abbreviations, the `zsh-abbr` plugin exists; otherwise use
  `shellAliases`.

### Defining functions / env in the work module

```nix
lib.mkIf config.nixfiles.work.acme.enable {
  home.packages = with pkgs; [ jira-cli-go buildkite-cli ];
  programs.zsh = {
    shellAliases = {
      hsu = "hotel services up";
      hsd = "hotel services down";
    };
    sessionVariables._ZO_EXCLUDE_DIRS = "$HOME/hotel";
    initContent = ''
      clone() { git clone "https://github.com/acme/$1" "''${2:-}"; cd "''${2:-$1}"; }
    '';
  };
}
```

Note: zsh gets package completions automatically once
`enableCompletion = true` and the tool is on `$PATH` — no manual completion
files needed in most cases.

---

## 13. First-run bootstrap (hand to the friend)

1. Install Nix (the Determinate Systems installer is easiest; flakes on by
   default). Otherwise enable `experimental-features = nix-command flakes`.
2. `git clone` the new repo, `cd` in.
3. Edit `hosts/personal.nix` → set `username` / `homeDirectory`.
4. `./scripts/switch personal` (works without home-manager pre-installed thanks
   to §8).
5. Open a new shell; confirm zsh + starship + tools are live.
6. Add `mac-app-util` + a GUI app, switch, confirm it appears in Spotlight (§5).

---

## Suggested build order (checklist)

1. [ ] `flake.nix` + `lib/mkHost.nix` + one `hosts/personal.nix` with only
       `programs.zsh.enable = true;`. Get a green `switch`.
2. [ ] Add `scripts/switch` + `scripts/news` (§8).
3. [ ] Establish the **per-app file** convention (§3) with git, **zsh**,
       starship — using their `programs.*` modules, not packages, to set the
       module-first pattern (§11) from the first commit.
4. [ ] Add `configs/nix-search.nix` (§10) — you'll use it to discover modules
       while building everything else.
5. [ ] Add `mac-app-util` + first GUI app; verify Spotlight (§5).
6. [ ] Add `configs/mcp.nix` with `programs.mcp` + one agent with
       `enableMcpIntegration` (§4).
7. [ ] Add the **personal/work split**: work option module + `hosts/work.nix`;
       move a work package behind it (§2).
8. [ ] Add `imds-broker` + `sandy` inputs and the overlay (§6).
9. [ ] Add the macOS `defaults write` activation + a packaged `.app` (§7).
10. [ ] Document + adopt the `mkOutOfStoreSymlink` writable-config pattern for one
        app (§9), and put the §11 decision checklist in the README.
```
