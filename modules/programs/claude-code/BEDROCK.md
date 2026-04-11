# Bedrock configuration

Claude Code uses AWS Bedrock inference profiles for model access. Configuration is managed through the `wilma` home-manager module, which is imported from the [wilma](https://github.com/cultureamp/wilma) flake.

## How it works

The `wilma` module handles Bedrock configuration in two phases:

1. **At eval time** (during `home-manager switch`): Sets up Bedrock mode, AWS credentials, region, and other static settings in `~/.claude/settings.json`.
2. **At activation time** (after settings.json is written): Runs `wilma nix-apply` to resolve model IDs to inference profile ARNs via the AWS API, then patches the resolved ARNs into `settings.json`.

## Configuration

In `hosts/culture-amp.nix`:

```nix
wilma = {
  enable = true;
  profiles = {
    primary = "global.anthropic.claude-opus-4-6-v1";
    small = "global.anthropic.claude-haiku-4-5-20251001-v1:0";
  };
};
```

Profile values can be either:
- **Model IDs** (e.g. `global.anthropic.claude-opus-4-6-v1`) — resolved to ARNs at activation time
- **Full ARNs** (e.g. `arn:aws:bedrock:us-west-2:...`) — passed through directly

## Updating models

To switch to a different model, update the profile values in `hosts/culture-amp.nix` and run:

```sh
home-manager switch --flake .#work
```

To see what inference profiles are available:

```sh
wilma list
```

## Troubleshooting

If activation reports "failed to resolve profiles", ensure AWS credentials are available. The activation script uses your configured `granted` profile to authenticate.

The `--impure` flag is no longer required for the work build.
