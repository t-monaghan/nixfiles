import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const config = readFileSync("modules/tools/omniwm.nix", "utf8");
const pattern = config.match(/huddleTitleRegex = "([^"]+)";/)[1];
const script = resolve("modules/tools/omniwm/follow-huddle.sh");
const window = (overrides = {}) => ({
  id: "huddle",
  app: { bundleId: "com.tinyspeck.slackmacgap" },
  title: "team_sre_foundations - Culture Amp - Slack",
  mode: "floating",
  isScratchpad: false,
  workspace: { rawName: "workspace-3" },
  ...overrides,
});

function run(windows, workspace = "workspace-2", ok = true) {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "omniwm-huddle-"));
  try {
    writeFileSync(join(dir, "omniwmctl"), `#!${process.execPath}
const args = process.argv.slice(2);
if (args[0] === "query") {
  const payload = args[1] === "active-workspace"
    ? { workspace: ${JSON.stringify(workspace ? { rawName: workspace } : null)} }
    : { windows: ${JSON.stringify(windows)} };
  console.log(JSON.stringify({ ok: ${ok}, result: { payload } }));
} else {
  console.log(JSON.stringify(args));
}
`, { mode: 0o755 });
    const result = spawnSync("bash", ["-euo", "pipefail", script], {
      env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, HUDDLE_TITLE_REGEX: pattern },
      encoding: "utf8",
    });
    return { ...result, moves: result.stdout.trim().split("\n").filter(Boolean).map(JSON.parse) };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("huddle follows the active workspace without a focus command", () => {
  const result = run([window()]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.moves, [["window", "move-to-workspace", "huddle", "workspace-2"]]);
});

test("huddle does not move again on its destination workspace", () => {
  const result = run([window()], "workspace-3");
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.moves, []);
});

test("main Slack windows, other apps, and scratchpads do not follow", () => {
  const result = run([
    window({ mode: "tiling" }),
    window({ title: "Unread Messages - Culture Amp - Slack" }),
    window({ title: "Huddles - Culture Amp - Slack" }),
    window({ title: "channel (Channel) - Culture Amp - Slack" }),
    window({ app: { bundleId: "another.app" } }),
    window({ isScratchpad: true }),
  ]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.moves, []);
});

test("no huddle is a successful no-op", () => {
  const result = run([]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.moves, []);
});

test("missing workspace or unsuccessful query cannot move windows", () => {
  for (const result of [run([window()], null), run([window()], "workspace-2", false)]) {
    assert.notEqual(result.status, 0);
    assert.deepEqual(result.moves, []);
  }
});

test("watcher handles workspace, monitor, and window changes and reconnects", () => {
  assert.match(config, /active-workspace,focused-monitor,windows-changed/);
  assert.match(config, /"--reconnect"/);
  assert.match(config, /titleRegex = huddleTitleRegex;/);
});
