import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const source = resolve("modules/tools/rex");
const fixture = {
  actions: [{ name: "show_shortcuts", title: "Show Configured Shortcuts" }],
  bindings: [
    { keys: ["alt+shift+[Slash]"], action: "show_shortcuts" },
    { keys: ["cmd+r"], action: "session.rename" },
    { keys: ["cmd+shift+h"], action: "pane.focus", args: { direction: "left" } },
    { keys: ["cmd+shift+ctrl+h"], action: "pane.resize", args: { direction: "left", amount: 5 } },
  ],
};

test("shortcut rows include configured keys, titles, and arguments", () => {
  const result = spawnSync("jq", ["-r", "-f", join(source, "shortcut-rows.jq")], {
    input: JSON.stringify(fixture), encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /cmd\+r    session\.rename/);
  assert.match(result.stdout, /alt\+shift\+\[Slash\]    Show Configured Shortcuts/);
  assert.match(result.stdout, /pane\.resize    amount=5 direction=left/);
  assert.equal(result.stdout.trim().split("\n").length, 4);
});

for (const status of [0, 1, 130, 2]) {
  test(`shortcuts popup handles fzf status ${status}`, { skip: !process.env.PI_SESSION_TEMP }, () => {
    const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-shortcuts-test-"));
    try {
      writeFileSync(join(dir, "rex"), `#!/bin/bash\nprintf '%s' '${JSON.stringify(fixture)}'\n`, { mode: 0o755 });
      writeFileSync(join(dir, "fzf"), `#!/bin/bash
[[ -z "$FZF_DEFAULT_OPTS" && -z "$FZF_DEFAULT_OPTS_FILE" ]] || exit 3
[[ "$*" == *'esc:abort,enter:ignore'* ]] || exit 3
while IFS= read -r line; do :; done
exit ${status}
`, { mode: 0o755 });
      const result = spawnSync("bash", ["-euo", "pipefail", join(source, "show-shortcuts.sh")], {
        encoding: "utf8",
        env: { ...process.env, PATH: `${dir}:${process.env.PATH}`,
          REX_SHORTCUT_ROWS: join(source, "shortcut-rows.jq"),
          FZF_DEFAULT_OPTS: "--bind=esc:ignore", FZF_DEFAULT_OPTS_FILE: "/missing" },
      });
      assert.equal(result.status, status === 2 ? 2 : 0, result.stderr);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}

const rex = process.env.REX_BIN_DIR && join(process.env.REX_BIN_DIR, "rex");
test("shortcut actions bind the requested keys and open a focused floating layer", {
  skip: !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP,
}, () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-shortcut-actions-"));
  try {
    const script = join(dir, "test.lua");
    writeFileSync(script, `
local actions, bindings, layer = {}, {}, {}
local mock = {
  action = function(action) actions[action.name] = action.run end,
  bind = function(key, action) bindings[key] = action end,
  session = { new_layer = function(options) layer.options = options; return { layer_id = "popup" } end },
}
local env = setmetatable({ rex = mock, require = function(name)
  if name == "session-settings" then return { shortcuts_popup = "/bin/rex-shortcuts-popup" } end
  return {}
end }, { __index = _G })
local function load(name)
  local file = assert(io.open(${JSON.stringify(source + "/")} .. name, "r"))
  local code = file:read("*a"); file:close()
  setfenv(assert(loadstring(code)), env)()
end
load("configured-sessions.lua")
load("init.lua")
assert(bindings["cmd+r"] == "session.rename")
assert(bindings["cmd+w"] == "client.window.close")
assert(bindings["cmd+shift+r"] == "client.config.reload")
assert(bindings["alt+shift+c"] == "reload_sessions")
assert(bindings["alt+shift+[Slash]"] == "show_shortcuts")
assert(bindings["cmd+shift+[Slash]"] == nil)
assert(not pcall(actions.show_shortcuts, {}))
local result = actions.show_shortcuts({ client_id = "app", session_id = "session" })
assert(result.layer_id == "popup")
assert(layer.options.focus == true and layer.options.bounds[3] == 0.8)
assert(layer.options.layout.block.options.shell == "none")
assert(layer.options.layout.block.options.command[1] == "/bin/rex-shortcuts-popup")
`);
    const result = spawnSync(rex, ["--autostart=false", "do", script], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
