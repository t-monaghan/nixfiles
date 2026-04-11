## ADDED Requirements

### Requirement: Module exported from wilma flake
The wilma flake SHALL export a home-manager module that encapsulates all Bedrock/Claude Code configuration internals. Consumers SHALL not need to know about AWS profile names, credential commands, or env var structure.

#### Scenario: Flake exports homeModules
- **WHEN** a consumer adds wilma as a flake input
- **THEN** `wilma.homeModules.wilma` SHALL be available as a home-manager module

### Requirement: Profile configuration accepts named model slots
The module SHALL expose a `profiles` option as an attribute set where keys are profile slot names and values are Bedrock model identifiers or full inference profile ARNs.

#### Scenario: User configures primary and small profiles
- **WHEN** the user sets `wilma.profiles = { primary = "global.anthropic.claude-opus-4-6-v1"; small = "global.anthropic.claude-haiku-4-5-20251001-v1:0"; }`
- **THEN** the module SHALL accept this configuration without error

#### Scenario: User configures profiles with full ARNs
- **WHEN** the user sets a profile value to a full ARN string
- **THEN** the module SHALL pass the ARN through directly as the model value

### Requirement: Module maps profiles to claude-code settings
The module SHALL internally map profile slot names to the correct `programs.claude-code.settings` attributes (env vars, credential helpers, etc). The mapping logic is internal to the module.

#### Scenario: Profiles produce valid claude-code settings
- **WHEN** profiles are configured
- **THEN** the module SHALL set `programs.claude-code.settings.env` with the appropriate Bedrock model variables
- **AND** the module SHALL configure AWS credential export and refresh commands
- **AND** the module SHALL set `CLAUDE_CODE_USE_BEDROCK` to enable Bedrock mode

### Requirement: AWS credential plumbing is encapsulated
The module SHALL handle all AWS credential configuration internally. The credential profile name, granted commands, and empty-credential overrides SHALL be internal to the module, not exposed to the consumer.

#### Scenario: Consumer does not specify credential details
- **WHEN** the user only configures `wilma.profiles`
- **THEN** `programs.claude-code.settings.awsCredentialExport` and `awsAuthRefresh` SHALL be set correctly without any credential-related input from the consumer

### Requirement: Region configuration
The module SHALL expose a `region` option with a sensible default. The region is set as `AWS_REGION` in claude-code settings.

#### Scenario: Default region applied
- **WHEN** `wilma.region` is not explicitly set
- **THEN** `programs.claude-code.settings.env.AWS_REGION` SHALL be set to the module's default region

#### Scenario: Custom region override
- **WHEN** `wilma.region` is set to a different value
- **THEN** `programs.claude-code.settings.env.AWS_REGION` SHALL use the overridden value

### Requirement: Module does not require --impure flag
The module SHALL use only pure nix evaluation. All configuration values MUST be provided through module options, not external file imports or `builtins.getEnv`.

#### Scenario: Pure evaluation
- **WHEN** `home-manager switch --flake .#work` is run without `--impure`
- **THEN** the build SHALL succeed with wilma profiles correctly applied
