import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { omniwmSettings } from "./omniwm/settings.test-helper.mjs";

const rex = process.env.REX_BIN_DIR ? join(process.env.REX_BIN_DIR, "rex") : null;
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

test("Rex swaps the command palette and session picker shortcuts", () => {
  const source = readFileSync("modules/tools/rex/init.lua", "utf8");
  assert.match(source, /rex\.bind\("cmd\+k", "client\.palette\.toggle"\)/);
  assert.match(source, /rex\.bind\("cmd\+shift\+p", "session\.switch"\)/);
});

test("Rex leaves Ctrl-Tab on its default binding", () => {
  const source = readFileSync("modules/tools/rex/init.lua", "utf8");
  assert.doesNotMatch(source, /rex\.bind\("ctrl\+tab",/);
});

test("Rex direct shortcuts and recent-session history", { skip }, () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-test-"));
  const source = resolve("modules/tools/rex");
  try {
    const script = join(dir, "test.lua");
    writeFileSync(script, `
package.path = ${JSON.stringify(source + "/?.lua;")} .. package.path
local json = rex.json
local bindings, actions, handlers, queued = {}, {}, {}, {}
local live = { { session_id = "a" }, { session_id = "b" }, { session_id = "c" } }
local fail_list = { value = false }
local terminal_size = { rows = 80, fail = false }
local mock = {
  json = json,
  bind = function(key, action, args)
    assert(not bindings[key], "Duplicate binding: " .. key)
    bindings[key] = { action = action, args = args }
  end,
  action = function(action) actions[action.name] = action.run end,
  client = { queue = function(action, args) queued.action = action; queued.args = args end },
  on = function(event, handler) handlers[event] = handler end,
  invoke = function(action)
    error("History tracking must not invoke actions or create sessions: " .. action)
  end,
  call = function(method, args)
    if method == "com.superlogical.terminal.size" then
      assert(args.session_id == "a" and args.block_id == "block:focused")
      if terminal_size.fail then return nil, "size failed" end
      return { rows = terminal_size.rows }
    end
    if method == "session.new_split" then
      if fail_list.value then return nil, "split failed" end
      queued.split = args
      return { block_ids = { "block:new" } }
    end
    if method == "session.resize_pane" then
      queued.resize = args
      return {}
    end
    if method == "session.list" then
      if fail_list.value then return nil, "list failed" end
      return { sessions = live }
    end
    if method == "client.list" then
      return { clients = { { client_id = "app", info = { kind = "app" }, session_ids = { "a" } } } }
    end
    if method == "client.inspect" then
      return { client = { info = { kind = args.client_id == "cli" and "cli" or "app" } } }
    end
    error("Unexpected API call: " .. method)
  end,
}
local env = setmetatable({ rex = mock }, { __index = _G })
local function load(path)
  local file = assert(io.open(path, "r"))
  local code = file:read("*a")
  file:close()
  return setfenv(assert(loadstring(code, "@" .. path)), env)()
end
local history = load(${JSON.stringify(join(source, "history.lua"))})
env.require = function(name)
  if name == "configured-sessions" then return true end
  assert(name == "history"); return history
end
local path = ${JSON.stringify(join(dir, "history.json"))}
history.path = function() return path end
assert(next(history.read(path)) == nil)
local invalid = assert(io.open(path, "w"))
invalid:write('{"app":42}')
invalid:close()
assert(next(history.read(path)) == nil)
local clients = {}
history.record(clients, "app", "a")
history.record(clients, "app", "b")
history.record(clients, "app", "a")
assert(#clients.app == 2 and clients.app[1] == "a" and clients.app[2] == "b")
history.record(clients, "other", "c")
assert(history.previous(clients, "app", "a", { b = true }) == "b")
assert(history.previous(clients, "other", "a", { b = true }) == nil)
history.remove(clients, "b")
assert(history.previous(clients, "app", "a", { b = true }) == nil)
history.write(path, clients)
assert(history.read(path).app[1] == "a")

load(${JSON.stringify(join(source, "init.lua"))})
assert(bindings["cmd+k"].action == "client.palette.toggle")
assert(bindings["cmd+shift+p"].action == "session.switch")
assert(bindings["cmd+r"].action == "session.rename")
assert(bindings["cmd+w"].action == "client.window.close")
assert(bindings["cmd+shift+f"].action == "pi_kimi_popup")
assert(bindings["alt+shift+[Slash]"].action == "show_shortcuts")
assert(bindings["cmd+shift+[Slash]"] == nil)
assert(bindings["cmd+shift+a"].action == "last_session")
assert(bindings["ctrl+tab"] == nil)
assert(bindings["alt+shift+o"].action == "configured_sessions")
assert(bindings["alt+shift+p"].action == "worktree_picker")
assert(bindings["cmd+shift+o"] == nil and bindings["cmd+shift+w"] == nil)
assert(bindings["cmd+shift+ctrl+j"].action == "pane.resize")
assert(bindings["cmd+shift+j"].args.direction == "down")
assert(bindings["alt+u"].action == "pane.split" and bindings["alt+u"].args.direction == "down")
assert(bindings["alt+i"].action == "split_down_small")
assert(bindings["alt+o"].action == "pane.split" and bindings["alt+o"].args.direction == "right")
assert(bindings["cmd+d"] == nil and bindings["cmd+shift+d"] == nil and bindings["cmd+e"] == nil)
assert(bindings["cmd+shift+ctrl+d"] == nil and bindings["cmd+shift+alt+d"] == nil)
assert(not pcall(actions.split_down_small, {}))
actions.split_down_small({ session_id = "a", block_id = "block:focused" })
local split = queued.split
assert(split.session_id == "a" and split.anchor_id == "block:focused")
assert(split.direction == "vertical" and split.side == "after")
assert(math.abs((1 - split.ratio) * terminal_size.rows - 13) < 0.000001 and split.focus == true)
assert(split.layout.block.flavor == "com.superlogical.terminal.shell")
assert(queued.resize.session_id == "a" and queued.resize.direction == "vertical")
assert(queued.resize.before_block_id == "block:focused" and queued.resize.after_block_id == "block:new")
assert(queued.resize.ratio == split.ratio)
for _, rows in ipairs({ 40, 80, 160, 240 }) do
  terminal_size.rows = rows
  actions.split_down_small({ session_id = "a", block_id = "block:focused" })
  assert(math.abs((1 - queued.split.ratio) * rows - 13) < 0.000001)
  assert(queued.resize.ratio == queued.split.ratio)
end
terminal_size.rows = 20
actions.split_down_small({ session_id = "a", block_id = "block:focused" })
assert(queued.split.ratio == 0.5)
terminal_size.rows = 0
assert(not pcall(actions.split_down_small, { session_id = "a", block_id = "block:focused" }))
terminal_size.rows = 80
terminal_size.fail = true
assert(not pcall(actions.split_down_small, { session_id = "a", block_id = "block:focused" }))
terminal_size.fail = false
fail_list.value = true
assert(not pcall(actions.split_down_small, { session_id = "a", block_id = "block:focused" }))
fail_list.value = false
assert(bindings["cmd+shift+ctrl+n"].action == "session.new")
assert(bindings["alt+shift+c"].action == "reload_sessions")
assert(bindings["cmd+shift+r"].action == "client.config.reload")
for key in pairs(bindings) do
  assert((key == "alt+u" or key == "alt+i" or key == "alt+o" or key == "cmd+k" or key == "cmd+r" or key == "cmd+w" or key == "alt+shift+c" or key == "alt+shift+o" or key == "alt+shift+p"
    or key == "alt+shift+[Slash]" or key == "alt+shift+ctrl+w"
    or key:find("cmd+shift+", 1, true) == 1) and not key:find(">", 1, true))
end
local ok = pcall(actions.last_session, { client_id = "app", session_id = "a" })
assert(not ok, "A missing previous session must not switch to an arbitrary session")
assert(not pcall(actions.last_session, {}))

load(${JSON.stringify(join(source, "track-sessions.lua"))})
handlers.client_connected({ session_id = "b" }, { client_id = "app", session_id = "b" })
actions.last_session({ client_id = "app", session_id = "b" })
assert(queued.action == "session.select" and queued.args.session_id == "a", json.encode(queued))
handlers.client_connected({ session_id = "a" }, { client_id = "app", session_id = "a" })
actions.last_session({ client_id = "app", session_id = "a" })
assert(queued.args.session_id == "b")
load(${JSON.stringify(join(source, "track-sessions.lua"))})
assert(history.read(path).app[2] == "b", "History must survive tracker restarts")
handlers.client_connected({ session_id = "c" }, { client_id = "cli", session_id = "c" })
assert(history.read(path).cli == nil)
handlers.client_connected({ session_id = "c" }, { client_id = "other", session_id = "c" })
assert(history.read(path).app[1] == "a")
handlers.session_destroyed({}, { session_id = "b" })
assert(not pcall(actions.last_session, { client_id = "app", session_id = "a" }))
history.record(clients, "app", "b")
history.write(path, clients)
live[2], live[3] = nil, nil
assert(not pcall(actions.last_session, { client_id = "app", session_id = "a" }))
fail_list.value = true
assert(not pcall(actions.last_session, { client_id = "app", session_id = "a" }))
return { bindings = bindings }
`);
    const result = spawnSync(rex, ["--autostart=false", "do", script, "--json"], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    const { bindings } = JSON.parse(result.stdout);
    assert.equal(Object.keys(bindings).length, 41);

    const normalise = key => key.toLowerCase().split("+")
      .map(part => ({ command: "cmd", option: "alt", control: "ctrl" })[part] ?? part)
      .sort().join("+");
    const rexKeys = new Set(Object.keys(bindings).map(normalise));
    assert.equal(rexKeys.size, Object.keys(bindings).length, "Duplicate resolved shortcut");
    for (const { binding } of omniwmSettings().hotkeys) {
      if (binding === "Unassigned") continue;
      assert(!rexKeys.has(normalise(binding)), `OmniWM conflict: ${binding}`);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
