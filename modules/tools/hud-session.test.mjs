import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const script = resolve(import.meta.dirname, "hud-session.sh");

for (const attached of [false, true]) {
  test(`hud waits for its own session to attach (initially attached: ${attached})`, () => {
    const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "hud-session-test-"));
    try {
      writeFileSync(join(dir, "tmux"), `#!/bin/sh
printf '%s\\n' "$*" >> "$HUD_TEST_DIR/calls"
if [ -f "$HUD_TEST_DIR/attached" ]; then
  echo 1
else
  touch "$HUD_TEST_DIR/attached"
  echo 0
fi
`, { mode: 0o755 });
      writeFileSync(join(dir, "hud"), `#!/bin/sh
printf 'hud %s\\n' "$*" >> "$HUD_TEST_DIR/calls"
exit 7
`, { mode: 0o755 });
      if (attached) writeFileSync(join(dir, "attached"), "");
      const result = spawnSync("bash", ["-e", script, "--test-argument"], {
        env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, TMUX_PANE: "%42", HUD_TEST_DIR: dir },
        encoding: "utf8",
        timeout: 5000,
      });
      assert.equal(result.status, 7, result.stderr);
      const query = "display-message -p -t %42 #{session_attached}";
      assert.deepEqual(readFileSync(join(dir, "calls"), "utf8").trim().split("\n"), [
        ...Array(attached ? 1 : 2).fill(query),
        "hud --test-argument",
      ]);
    } finally { rmSync(dir, { recursive: true, force: true }); }
  });
}
