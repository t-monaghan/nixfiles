# Refactor plan

A review of the repository (4,644 lines of Nix at the time of writing).
Suggestions in rough order of payoff.

## 1. Remove the duplicated Neovim configuration (~1,000 lines, 22% of the repo) — DONE

`modules/configs/{nixvim,neovim-plugins,neovim-lsp,neovim-obsidian}.nix` and
`nixos/modules/neovim/*` are near-copies. The diffs are small and enumerable:

- `termguicolors = true` and `extraPackages` (formatters) exist only on the
  NixOS side
- the macOS light/dark autocmd and the Monokai-light contrast overrides exist
  only on the Mac side
- `neovim-lsp.nix`: nixd uses `builtins.getFlake ${flakePath}` on the Mac,
  `<nixpkgs>` on the box
- `neovim-obsidian.nix`: identical except `enable = true` vs `false`

Consolidate into one module set under `modules/configs/neovim/` with two
parameters (e.g. `isDarwin = pkgs.stdenv.isDarwin` and an optional
`flakePath`). The macOS-only autocmd is already guardable with
`pkgs.stdenv.isDarwin`. Every future keymap or plugin change then lands once
instead of twice — the `modes.char.enabled` diff and the missing formatter
packages on the Mac side show the copies have already drifted.

**Done.** The shared module set lives at `modules/configs/neovim/`
(`default.nix`, `plugins.nix`, `lsp.nix`, `obsidian.nix`);
`nixos/modules/neovim/` is deleted. Host differences:

- `flakePath` + `homeConfigName` are optional parameters (Mac only); when
  null, nixd uses the channel expressions in `lsp.nix`.
- `pkgs.stdenv.isDarwin` gates the `UIEnter` appearance probe, the
  `boost_light_contrast` overrides, and the Obsidian plugin.

Deliberate unifications (small behaviour changes):

- `opts.termguicolors = true` now applies on the Macs too (was NixOS-only;
  Ghostty and Alacritty both support truecolor).
- The conform formatter `extraPackages` (alejandra, nixpkgs-fmt, stylua,
  ruff, prettierd) now apply on the Macs too (they were already in
  `home.packages`, so no new store paths).
- `plugins.flash.settings.modes.char.enabled = false` now applies on the
  NixOS box too (was Mac-only drift).

Anomaly kept as-is: `boost_light_contrast` targets Monokai Pro Light
(now the NixOS light theme) but runs only on the Macs (whose light theme is
Solarized Light). Revisit when merging the colour files (step 2). **Resolved in
step 2.**

## 2. Merge the two colour files — DONE

`modules/configs/colours.nix` and `nixos/lib/colours.nix` share all base16
values and differ only in the light theme names and the `tmux` block. One file
with a `dark`/`light` theme-name attribute per consumer, or a base file plus a
small per-host override, removes the second copy.

**Done**, and then taken further: no program is handed a theme name at all any
more (see "Two palettes, no theme names" below).

`modules/configs/colours.nix` is now the only palette; `nixos/lib/colours.nix` is
deleted and `nixos/neovim.nix` imports the shared file. No per-host override was
needed:

- The `tmux` block was already absent from the NixOS copy and is read by
  `modules/configs/tmux.nix`, which all three machines import — so it belongs in
  the shared file unconditionally.
- The light theme names differed only through drift. The Macs' Solarized Light
  values win. On the box, `nixvim.light`, `ghostty` and `zed` are consumed only
  behind `pkgs.stdenv.isDarwin` or in Mac-only modules, so the sole visible
  change there is `bat.light`: `Monokai Pro Light` → `Solarized (light)`.

The step-1 anomaly is resolved: `boost_light_contrast` and the
`monokai-pro-nvim` plugin are both deleted. They existed because Monokai Pro
Light's `Visual`, `Search` and `Comment` colours were near-invisible on its own
background; the palette now defines those slots itself, so there is nothing to
patch over.

## 2a. Two palettes, no theme names — DONE

Each program used to name a theme it had not got from this repo
(`base16-everforest-dark-hard`, `iTerm2 Solarized Light`, `gruvbox-dark`,
`Monokai Pro Light`, `Solarized (light)`). Nothing required that: the names were
the cheapest way to get a theme, and the result was a combination nobody chose —
bat rendered Gruvbox while Neovim rendered Everforest.

`colours.nix` now holds exactly two complete base16 palettes, `palettes.dark`
(Everforest Dark Hard) and `palettes.light` (Solarized Light), 16 slots each.
Editing a hex value changes every program on every machine. The semantic aliases
(`accent`, `warn`, `error`, …) are gone: each only restated a slot, and `accent`
and `ok` were both `base0B`.

How each program consumes them:

| Program | Mechanism |
| --- | --- |
| nixvim | `colorschemes.base16.colorscheme` takes the 16 slots directly; `auto-dark-mode` calls `base16.setup(<table>)` to swap palettes |
| ghostty | `programs.ghostty.themes` generates `themes/nixfiles-{dark,light}`; `theme = "light:nixfiles-light,dark:nixfiles-dark"` |
| zed | `programs.zed-editor.themes` generates `themes/nixfiles.json` holding both modes, mapped onto Zed's style keys |
| bat | `--theme=base16`, which renders through ANSI 0–21 — one theme covers both modes |
| fish, tmux, starship | ANSI colour names and indices, no hex |

The four terminal programs work because `colours.nix` also defines
`terminalPalette`, the base16 → ANSI index mapping (0–21) that Ghostty writes
into both theme files. Naming an ANSI slot instead of a hex value is what makes
them follow the appearance mode with no configuration of their own — starship
already did this. `tmux`'s hand-picked mid-tone hex became `colour20` (`base04`),
which base16 defines as readable in both modes. Over SSH to `dolomite`, these
follow the Mac's Ghostty palette, so the box matches the Mac automatically.

Two programs cannot follow the mode, having no appearance hook, and use
`palettes.dark`: Alacritty (a terminal, needs literal hex) and jankyborders.

Verified by running the built Neovim against the generated config: dark renders
`String #a7c080`, `Keyword #d699b6`, `Comment #868d80`, `NormalFloat #323c41`;
light renders `String #859900`, `Comment #839496`, `Search bg #b58900`. The
built-in `base16-everforest-dark-hard` scheme it replaced uses identical values
for `base08`–`base0E`, so dark syntax colours are unchanged; only the UI greys
shift by a few percent.

## 3. Convert function-call config files to home-manager modules

Most files in `modules/configs/` are functions:
`programs.nixvim = import ./configs/nixvim.nix {inherit pkgs colors flakePath homeConfigName;}`.
This forces manual argument threading (`flakePath` and `homeConfigName` pass
through `mkHost` → `home.nix` → `nixvim.nix` → `neovim-lsp.nix` via
`_module.args`). If each file is a module added to `imports`, then `pkgs`,
`lib`, `config`, and `extraSpecialArgs` arrive automatically. Pass `colors` and
`fonts` once via `_module.args` (or a `nixfiles.colours` option) instead of per
call site.

## 4. Split `modules/home.nix` (247 lines)

It mixes package lists, macOS `defaults write` activation, SSH config, and a
full inline Alacritty configuration (~60 lines). Alacritty is the only GUI
program configured inline while ghostty, zed, and aerospace each have their
own file — extract `configs/alacritty.nix` for consistency, and consider
grouping the file into `darwin-gui.nix` + `darwin-defaults.nix` + the package
list.

## 5. Remove small redundancies

- `hosts/personal.nix` adds `devbox` to `home.packages`, but
  `modules/home.nix` already lists `devbox`. Delete one.
- `hosts/personal.nix` sets `nixfiles = {};` — a no-op; delete the line.
- `sesh-plan.md` and `worktrunk-todo.md` at the repo root are planning notes;
  move them to a `docs/` directory or delete them once complete.
- `flake.nix` destructures all eleven inputs in `outputs` but only passes
  `inputs` onward (plus four names inside `mkHost`). `outputs = inputs: …`
  with `inputs.agenix.nixosModules.default` etc. removes the list you must
  update per new input.

## 6. Share the overlay between `mkHost` and `mkNixosHost`

The `sandy`/`imds-broker`/`worktrunk` overlay lives only in `lib/mkHost.nix`.
Extract it to `lib/overlays.nix` so the NixOS host can use the same package
set, and so the worktrunk test-skip workaround has one home.

## 7. Add repository-level checks

The repo has no `checks` or `formatter` flake outputs. Add:

- `formatter = pkgs.alejandra;` (alejandra is already installed) so `nix fmt`
  works
- a `checks` output that evaluates all three configurations
  (`homeConfigurations.{work,personal}.activationPackage`,
  `nixosConfigurations.dolomite.config.system.build.toplevel`) so
  `nix flake check` catches evaluation errors on all hosts before a
  `scripts/switch` on the affected machine does

Items 1–3 are the structural ones; item 1 alone removes about one fifth of the
repository and ends the drift between the Mac and NixOS Neovim configurations.
