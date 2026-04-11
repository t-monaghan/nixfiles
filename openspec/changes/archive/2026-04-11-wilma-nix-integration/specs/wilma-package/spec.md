## ADDED Requirements

### Requirement: Wilma CLI available as a nix package
The wilma flake SHALL export the wilma CLI binary as a nix package built with `buildGoModule`.

#### Scenario: Package exported from flake
- **WHEN** a consumer references `wilma.packages.${system}.default`
- **THEN** the wilma CLI binary SHALL be built from the Go source in the repo

### Requirement: Package available in PATH when module enabled
The module SHALL add the wilma binary to `home.packages` when enabled, so the user can run wilma commands from their shell.

#### Scenario: Binary available after home-manager switch
- **WHEN** the wilma module is enabled
- **THEN** the `wilma` command SHALL be available in the user's PATH

### Requirement: Flake input uses private repository
The flake input for wilma SHALL reference the private GitHub repository. Authentication relies on the user's existing git credential configuration.

#### Scenario: Flake lock resolves private repo
- **WHEN** `nix flake lock` is run
- **THEN** the wilma input SHALL resolve using the user's configured git credentials

### Requirement: Package is optional
The wilma nix package SHALL only be built and included when the module is enabled.

#### Scenario: Package not built when disabled
- **WHEN** the wilma module is not enabled
- **THEN** the wilma package SHALL NOT be built or added to `home.packages`
