## Why

Claude Code's Bedrock configuration requires a manual, error-prone workflow: run `wilma update-claude`, then hand-copy env vars into `~/.config/nixfiles/bedrock.nix` before every `home-manager switch`. This file is loaded with `builtins.pathExists` + `builtins.getEnv "HOME"` (requiring `--impure`), and forgetting the copy step silently loses model config. A declarative nix module should own this configuration so that profile selection is version-controlled and applied automatically.

## What Changes

- Add a home-manager module to the **wilma repo** that encapsulates all Bedrock/Claude Code configuration internals (env var mapping, AWS credential plumbing, region handling). The nixfiles repo should have minimal exposure to how wilma works.
- Add a `flake.nix` to the wilma repo that exports the home-manager module and optionally the wilma CLI package.
- In nixfiles: add wilma as a flake input, import the module, and configure it with just profile identifiers.
- Remove the `bedrock.nix` external-file indirection from `modules/work/culture-amp/home.nix`.
- Remove the `--impure` requirement for the work configuration build.
- Update `BEDROCK.md` to reflect the new workflow.

## Capabilities

### New Capabilities
- `wilma-module`: Home-manager module (in the wilma repo) that accepts profile configuration and produces claude-code Bedrock settings. Encapsulates all internal details — AWS profile names, credential commands, env var structure.
- `wilma-package`: Nix package derivation for the wilma CLI binary, exported from the wilma repo's flake.

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **wilma repo (cultureamp/wilma)**: New `flake.nix` and `nix/` directory with module and package definitions
- **nixfiles flake.nix**: Add wilma flake input
- **nixfiles hosts/culture-amp.nix**: Add `wilma.profiles` configuration
- **nixfiles modules/work/culture-amp/home.nix**: Remove bedrock.nix loading
- **nixfiles modules/programs/claude-code/BEDROCK.md**: Rewrite to document new workflow
