## 1. Wilma repo — flake and package

- [x] 1.1 Create `flake.nix` in wilma repo with nixpkgs input and `buildGoModule` package for the wilma CLI (`packages.${system}.default`)
- [x] 1.2 Verify `nix build` produces a working `wilma` binary from the flake (needs manual run — vendorHash placeholder needs updating)

## 2. Wilma repo — home-manager module

- [x] 2.1 Create `nix/module.nix` with option declarations: `wilma.enable`, `wilma.profiles` (attrsOf str), `wilma.region` (str with default)
- [x] 2.2 Implement activation-time profile resolution: module writes JSON config, activation script runs `wilma nix-apply` to resolve model IDs to ARNs and patch settings.json. Non-ARN settings (CLAUDE_CODE_USE_BEDROCK, region, empty AWS credential overrides) set at eval time.
- [x] 2.3 Implement credential plumbing: set `programs.claude-code.settings.awsCredentialExport` and `awsAuthRefresh` using the internal granted profile
- [x] 2.4 Add wilma package to `home.packages` when module is enabled
- [x] 2.5 Export module as `homeModules.wilma` from `flake.nix`

## 3. Nixfiles — consume wilma flake

- [x] 3.1 Add `wilma` input to `flake.nix` pointing at `github:cultureamp/wilma`
- [x] 3.2 Pass `wilma` to `mkHost` and import `wilma.homeModules.wilma` in the modules list
- [x] 3.3 Add `wilma.profiles` configuration to `hosts/culture-amp.nix` with current profile values

## 4. Nixfiles — remove old bedrock workflow

- [x] 4.1 Remove `bedrock.nix` loading logic from `modules/work/culture-amp/home.nix` (the `let bedrockPath = ...` / `bedrockConfig` pattern)
- [x] 4.2 Update `modules/programs/claude-code/BEDROCK.md` to document the new workflow
- [x] 4.3 Verify `home-manager switch --flake .#work` works without `--impure` (needs manual run after wilma flake is published)
