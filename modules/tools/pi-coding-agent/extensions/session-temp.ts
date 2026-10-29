import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdirSync } from "fs";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!process.env.PI_SESSION_TEMP) {
      // Must live under a path the sandbox actually permits writes to.
      // @anthropic-ai/sandbox-runtime hardcodes `/tmp/claude` as a default
      // write path (getDefaultWritePaths, both macOS + Linux), but NOT the
      // macOS `$TMPDIR` (/var/folders/.../T). That dir is only auto-allowed
      // when the *sandboxed* process's TMPDIR matches the macOS pattern, and
      // pi overrides tool TMPDIR to /tmp/claude — so /var/folders is never
      // writable from tools. This extension runs in the unsandboxed main
      // process where process.env.TMPDIR is the (unwritable) /var/folders path,
      // so basing PI_SESSION_TEMP on it produces a dir that mkdir's fine here
      // but that every sandboxed tool then fails to write to. Base it on
      // /tmp/claude instead so it's writable everywhere.
      const baseDir = "/tmp/claude";
      const dir = `${baseDir}/pi-session/${ctx.sessionManager.getSessionId()}`;
      mkdirSync(dir, { recursive: true });
      process.env.PI_SESSION_TEMP = dir;
    }
  });

  pi.on("before_agent_start", async (event, _ctx) => {
    const additionalInstructions = `\nIMPORTANT: Use $PI_SESSION_TEMP for ALL temp files, cloning, downloads — never /tmp. Use http:// for git clone.`;

    return {
      systemPrompt: event.systemPrompt + additionalInstructions,
    };
  });
}
