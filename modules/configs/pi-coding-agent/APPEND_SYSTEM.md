# Env

In sandbox mode, bash commands use `@anthropic-ai/sandbox-runtime`. The sandbox extension also checks read, write, and edit paths. MCP tools and other extensions do not run inside this sandbox. Read `~/.pi/agent/sandbox.json` for the global policy and `.pi/sandbox.json` for project overrides. Permission grants last for the current session only. Prompt mode disables the OS sandbox and asks before each read, write, edit, or bash operation.
