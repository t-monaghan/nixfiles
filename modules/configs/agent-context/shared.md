## PR Format

PR descriptions should include the following sections:

- **Problem** — What issue or need does this address?
- **Why this change** — Why is this the right approach?
- **Other changes** (optional) — Include this section when there are unusual or supplementary changes bundled in the PR (e.g. adding the multi-gitter flake, tooling updates, config changes unrelated to the main purpose).

## PR Comments

Never comment on GitHub on behalf of the user without being asked to.

## OpenSpec

This user uses [fission-ai/openspec](https://github.com/fission-ai/openspec) for spec-driven development. Run it with:

```bash
npx @fission-ai/openspec@latest <command>
```

### Common commands

- `npx @fission-ai/openspec@latest init` — Initialize OpenSpec in a project
- `npx @fission-ai/openspec@latest list` — List changes and specs
- `npx @fission-ai/openspec@latest view` — Interactive terminal dashboard
- `npx @fission-ai/openspec@latest validate` — Check artifacts for structural issues
- `npx @fission-ai/openspec@latest archive` — Finalize completed changes
- `npx @fission-ai/openspec@latest status` — Display artifact completion progress
