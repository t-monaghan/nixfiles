import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { join, resolve } from "node:path";

const extension = resolve(import.meta.dirname, "pi-coding-agent/extensions/hud-registry.ts");

test("registry follows a session switch and remains on the new session", () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "hud-registry-test-"));
  try {
    const script = `
      import register from ${JSON.stringify(extension)};
      const handlers = new Map();
      let heartbeat;
      globalThis.setInterval = fn => { heartbeat = fn; return { unref() {} }; };
      register({ on(event, handler) { handlers.set(event, handler); } });
      const context = file => ({ cwd: '/repo', mode: 'tui', sessionManager: {
        getSessionFile: () => file, getSessionId: () => file, getSessionName: () => file,
      } });
      await handlers.get('session_start')(null, context('old.jsonl'));
      await handlers.get('session_before_switch')();
      await handlers.get('session_switch')(null, context('new.jsonl'));
      heartbeat();
    `;
    const state = join(dir, "pi-hud", "active");
    const result = spawnSync(process.execPath, ["--input-type=module", "-e", script], {
      encoding: "utf8", env: { ...process.env, XDG_STATE_HOME: dir, TMUX: "", TMUX_PANE: "" },
    });
    assert.equal(result.status, 0, result.stderr);
    const registry = JSON.parse(readFileSync(join(state, `${result.pid}.json`), "utf8"));
    assert.equal(registry.file, "new.jsonl");
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
