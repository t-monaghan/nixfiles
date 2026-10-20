import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { join, resolve } from "node:path";

const extension = resolve(import.meta.dirname, "pi-coding-agent/extensions/hud-registry.ts");

test("registry tracks concurrent permission prompts and clears them on session switch", () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "hud-registry-test-"));
  try {
    const script = `
      import register from ${JSON.stringify(extension)};
      const handlers = new Map();
      const events = new Map();
      let heartbeat;
      globalThis.setInterval = fn => { heartbeat = fn; return { unref() {} }; };
      register({ on(event, handler) { handlers.set(event, handler); }, events: { on(event, handler) { events.set(event, handler); } } });
      const context = file => ({ cwd: '/repo', mode: 'tui', sessionManager: {
        getSessionFile: () => file, getSessionId: () => file, getSessionName: () => file,
      } });
      const fs = await import('node:fs');
      const record = process.env.XDG_STATE_HOME + '/pi-hud/active/' + process.pid + '.json';
      const snapshot = () => JSON.parse(fs.readFileSync(record, 'utf8'));
      await handlers.get('session_start')(null, context('old.jsonl'));
      await handlers.get('agent_start')(null, context('old.jsonl'));
      events.get('attention:request')({ key: 'one' });
      events.get('attention:request')({ key: 'two' });
      if (!snapshot().waiting || !snapshot().working) throw Error('expected waiting while working');
      events.get('attention:resolve')({ key: 'one' });
      if (!snapshot().waiting) throw Error('resolved one of two prompts');
      events.get('attention:resolve')({ key: 'two' });
      if (snapshot().waiting) throw Error('prompt did not resolve');
      events.get('attention:request')({ key: 'three' });
      await handlers.get('session_before_switch')();
      await handlers.get('session_switch')(null, context('new.jsonl'));
      heartbeat();
      if (snapshot().waiting) throw Error('prompt survived session switch');
    `;
    const state = join(dir, "pi-hud", "active");
    const result = spawnSync(process.execPath, ["--input-type=module", "-e", script], {
      encoding: "utf8", env: { ...process.env, XDG_STATE_HOME: dir, TMUX: "", TMUX_PANE: "" },
    });
    assert.equal(result.status, 0, result.stderr);
    const registry = JSON.parse(readFileSync(join(state, `${result.pid}.json`), "utf8"));
    assert.equal(registry.file, "new.jsonl");
    assert.equal(registry.waiting, false);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
