## Context

Claude Code Bedrock auth is currently configured through a fragile manual pipeline:

1. `wilma update-claude` writes model ARNs + env vars to `~/.claude/settings.json`
2. Home-manager also owns `settings.json`, overwriting it on next `home-manager switch`
3. User manually copies values into `~/.config/nixfiles/bedrock.nix`
4. The work module loads this external file at eval time using `builtins.getEnv "HOME"` (requires `--impure`)

Wilma (at `cultureamp/wilma`) already knows how to generate the full claude-code settings — env vars, credential commands, region, the lot. The module should live in wilma's repo so that internal details stay internal.

The nixfiles repo follows a consistent module pattern: each program has `common.nix` (option declarations) and `home.nix` (implementation). Modules are auto-discovered recursively. External modules (like nixvim) are imported via flake inputs.

## Goals / Non-Goals

**Goals:**
- Declare Bedrock model profiles in nix config, version-controlled and reproducible
- Remove the `--impure` requirement from the work build
- Remove the manual bedrock.nix copy step entirely
- Package the wilma CLI via nix
- Keep wilma internals (AWS profiles, credential commands, env var structure) encapsulated in the wilma repo — nixfiles should have minimal exposure

**Non-Goals:**
- Reimplementing wilma's model discovery logic in nix — the module accepts explicit profile values
- Supporting auto-discovery from AWS at nix eval time
- Making the module work for non-home-manager setups

## Decisions

### 1. Module lives in the wilma repo, not nixfiles

The module encapsulates how profiles map to claude-code settings, which AWS credential commands to use, and which env vars to set. These are all wilma internals. If they live in nixfiles, changes to wilma's settings format require coordinated updates across repos.

Wilma exports `homeModules.wilma` from its flake, similar to how nixvim exports `homeModules.nixvim`.

**Alternative considered:** Module in nixfiles. Rejected because it would expose wilma internals (AWS profile names, credential command format, env var mapping) in the dotfiles repo.

### 2. Wilma repo gets a flake.nix

A minimal `flake.nix` in the wilma repo that exports:
- `homeModules.wilma` — the home-manager module
- `packages.${system}.default` — the wilma CLI built with `buildGoModule`

The module source lives under `nix/` in the wilma repo (e.g. `nix/module.nix`).

**Alternative considered:** `builtins.fetchGit` inline in nixfiles without a flake. Works but loses flake lock pinning and is less idiomatic.

### 3. Profile values are opaque strings

The user passes whatever identifier works — a Bedrock model ID like `global.anthropic.claude-opus-4-6-v1` or a full ARN. The module passes these through to the env vars without transformation. The module doesn't need to understand model ID structure.

### 4. Module sets programs.claude-code.settings via mkMerge

The wilma module produces `programs.claude-code.settings` config that gets merged with the claude-code module's own settings. This is the same mechanism the current `bedrock.nix` uses — the only difference is the source.

### 5. Nixfiles consumption is minimal

In nixfiles, the integration is:

**flake.nix** — add input:
```nix
wilma.url = "github:cultureamp/wilma";
```

**flake.nix** — import module in mkHost:
```nix
modules = [
  nixvim.homeModules.nixvim
  wilma.homeModules.wilma
  ./hosts/${name}.nix
];
```

**hosts/culture-amp.nix** — configure:
```nix
wilma.profiles = {
  primary = "global.anthropic.claude-opus-4-6-v1";
  small = "global.anthropic.claude-haiku-4-5-20251001-v1:0";
};
```

That's it. No credential commands, no env var names, no AWS profile references in nixfiles.

### 6. Work module cleanup

`modules/work/culture-amp/home.nix` loses the `bedrock.nix` loading logic entirely. The `let bedrockPath = ...` / `bedrockConfig` pattern and the `--impure` flag are no longer needed.

## Risks / Trade-offs

**[Risk] Wilma repo needs changes (flake.nix + nix module)** → This is additive — no existing code modified. The module is a new nix directory alongside the existing Go code.

**[Risk] Go module hash changes on wilma updates** → Standard workflow: `nix flake update wilma` then fix hash if needed.

**[Risk] Private repo auth during nix build** → The user has git auth configured. Same pattern as any private flake input.

**[Trade-off] No auto-discovery** → Unlike `wilma update-claude`, the nix module requires explicit profile values. This is intentional — nix config should be explicit and reproducible.

**[Trade-off] Two repos to update** → When changing profile values, the user edits nixfiles. When changing how profiles map to settings, the user edits wilma. This separation is the point — wilma owns the internals.
