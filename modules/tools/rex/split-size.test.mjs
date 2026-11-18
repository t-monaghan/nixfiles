import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const rex = process.env.REX_BIN_DIR && join(process.env.REX_BIN_DIR, "rex");
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

for (const rows of [40, 80, 160]) {
  test(`Alt-i reserves approximately 12 rows from a ${rows}-row terminal`, { skip }, () => {
    const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-split-size-"));
    let session;
    const run = args => {
      const result = spawnSync(rex, ["--autostart=false", ...args], { encoding: "utf8" });
      assert.equal(result.status, 0, result.stderr);
      return JSON.parse(result.stdout);
    };
    try {
      session = run(["new", "split-size-verification", "--json", "--shell=none", "--", "/bin/sleep", "120"]);
      const anchor = session.initial_windows[0].block_ids[0];
      const script = join(dir, "split.lua");
      writeFileSync(script, `
local actions = {}
local env = setmetatable({ rex = {
  bind = function() end,
  action = function(action) actions[action.name] = action.run end,
  call = rex.call,
}, require = function() return {} end }, { __index = _G })
local file = assert(io.open(${JSON.stringify(resolve("modules/tools/rex/init.lua"))}, "r"))
local source = file:read("*a")
file:close()
setfenv(assert(loadstring(source)), env)()
assert(rex.call("session.own_block", {
  session_id = ${JSON.stringify(session.session_id)},
  block_ids = { ${JSON.stringify(anchor)} },
  mode = "take",
}))
assert(rex.call("com.superlogical.terminal.resize", {
  session_id = ${JSON.stringify(session.session_id)},
  block_id = ${JSON.stringify(anchor)},
  args = { columns = 100, rows = ${rows} },
}))
local size = assert(rex.call("com.superlogical.terminal.size", {
  session_id = ${JSON.stringify(session.session_id)},
  block_id = ${JSON.stringify(anchor)},
  args = {},
}))
assert(size.rows == ${rows})
actions.split_down_small({ session_id = ${JSON.stringify(session.session_id)}, block_id = ${JSON.stringify(anchor)} })
return assert(rex.call("session.view", { session_id = ${JSON.stringify(session.session_id)} }))
  `);
      const view = run(["do", script, "--session", session.session_id, "--json"]);
      const window = view.windows[0];
      const split = window.layers[0].layout.split;
      assert.equal(split.direction, "vertical");
      assert.equal(split.before.block_id, anchor);
      assert.equal(split.ratio, 1 - 13 / rows);
      assert(Math.abs(split.after.rect[3] * rows - 13) < 1e-9);
      assert.equal(window.focused_block_id, split.after.block_id);
    } finally {
      if (session) {
        const result = spawnSync(rex, ["--autostart=false", "kill", session.session_id], { encoding: "utf8" });
        assert.equal(result.status, 0, result.stderr);
      }
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
