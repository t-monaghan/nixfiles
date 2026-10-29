---
name: aws-sandy
description: Inspect or query AWS via the sandy CLI and the imds-broker MCP server. Use for ANY AWS task — listing resources, reading configuration, checking logs, S3, ECS, CodeArtifact, STS, etc. Never run the aws CLI; the sandbox blocks *.amazonaws.com, so aws CLI calls always fail.
---

# AWS access with sandy and imds-broker

Do not run the `aws` CLI. The pi sandbox network allowlist does not include
`*.amazonaws.com`, so every `aws` CLI call fails with a network error. Instead:

- **imds-broker (MCP server)** supplies AWS credentials for a profile via a
  local Instance Metadata Service (IMDS) server.
- **sandy (CLI)** runs TypeScript scripts that use the AWS SDK inside a Docker
  container, with credentials from the IMDS server.

## Workflow

1. **Learn the sandy script format** (required before writing a script):

   ```
   sandy resource sandy://skills/cli/resources/scripting-guide.md
   ```

2. **Pick a profile** with the `imds_broker_list_profiles` MCP tool
   (server `imds-broker`).

3. **Start an IMDS server** with the `imds_broker_create_server` MCP tool.
   Pass `profile` and, when the profile has no configured region, `region`.
   The result contains the `port` — pass it to sandy as `--imds-port`.

4. **Create a session and run a script**:

   ```
   sandy session create
   # write your TypeScript to .sandy/<session>/scripts/<name>.ts
   sandy run --session <session> --script <name>.ts --imds-port <port> [--region <region>]
   ```

   Script output written to `/workspace/output` appears in
   `.sandy/<session>/output/`.

5. **Stop the IMDS server** with `imds_broker_stop_server` when done.

## Backend rules

- The backend is set to `docker` in `~/.config/sandy/config.json` (managed in
  nixfiles). **Do not switch to the shuru backend** and do not run
  `sandy config` to change the backend.
- If the Docker backend fails, the cause is almost always one of:
  1. **OrbStack is not running.** Verify with `docker info`; ask the user to
     start OrbStack. Do not try to install or reconfigure Docker.
  2. **The IMDS server is stale.** `sandy check connect --imds-port <port>`
     fails: stop the server with `imds_broker_stop_server`, then create a new
     one with `imds_broker_create_server` and retry.
- Diagnose with `sandy check baseline` (sandbox works) and
  `sandy check connect --imds-port <port>` (credentials reachable).
- If the sandy image is missing, build it with `sandy image create`.
