import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const rex = process.env.REX_BIN_DIR ? join(process.env.REX_BIN_DIR, "rex") : null;
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

test("Rex swaps the command palette and session picker shortcuts", () => {
  const source = readFileSync("modules/tools/rex/init.lua", "utf8");
  assert.match(source, /rex\.bind\("cmd\+k", "client\.palette\.toggle"\)/);
  assert.match(source, /rex\.bind\("cmd\+shift\+p", "session\.switch"\)/);
});

test("Rex binds Ctrl-Tab to the most recently visited session", () => {
  const source = readFileSync("modules/tools/rex/init.lua", "utf8");
  assert.match(source, /rex\.bind\("ctrl\+tab", "last_session"\)/);
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
local startup = { ensured = 0, fail = false }
local mock = {
  json = json,
  bind = function(key, action, args)
    assert(not bindings[key], "Duplicate binding: " .. key)
    bindings[key] = { action = action, args = args }
  end,
  action = function(action) actions[action.name] = action.run end,
  client = { queue = function(action, args) queued.action = action; queued.args = args end },
  on = function(event, handler) handlers[event] = handler end,
  invoke = function(action, args)
    assert(action == "ensure_sessions" and args.include_remote == false)
    startup.ensured = startup.ensured + 1
    if startup.fail then return nil, "ensure failed" end
    return { ready = true }
  end,
  call = function(method, args)
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
assert(bindings["alt+shift+[Slash]"].action == "show_shortcuts")
assert(bindings["cmd+shift+[Slash]"] == nil)
assert(bindings["cmd+shift+a"].action == "last_session")
assert(bindings["ctrl+tab"].action == "last_session")
assert(bindings["alt+shift+o"].action == "configured_sessions")
assert(bindings["alt+shift+p"].action == "worktree_picker")
assert(bindings["cmd+shift+o"] == nil and bindings["cmd+shift+w"] == nil)
assert(bindings["cmd+shift+ctrl+j"].action == "pane.resize")
assert(bindings["cmd+shift+j"].args.direction == "down")
assert(bindings["cmd+shift+ctrl+d"].args.direction == "down")
assert(bindings["cmd+shift+ctrl+n"].action == "session.new")
assert(bindings["alt+shift+c"].action == "reload_sessions")
assert(bindings["cmd+shift+r"].action == "client.config.reload")
for key in pairs(bindings) do
  assert((key == "cmd+k" or key == "cmd+r" or key == "cmd+w" or key == "alt+shift+c" or key == "alt+shift+o" or key == "alt+shift+p"
    or key == "alt+shift+[Slash]" or key == "alt+shift+ctrl+w" or key == "ctrl+tab"
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
assert(startup.ensured == 2, "Each tracker start must ensure local sessions")
startup.fail = true
local ready, err = pcall(load, ${JSON.stringify(join(source, "track-sessions.lua"))})
assert(not ready and tostring(err):find("ensure failed", 1, true))
startup.fail = false
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
    assert.equal(Object.keys(bindings).length, 40);

    const normalise = key => key.toLowerCase().split("+")
      .map(part => ({ command: "cmd", option: "alt", control: "ctrl" })[part] ?? part)
      .sort().join("+");
    const rexKeys = new Set(Object.keys(bindings).map(normalise));
    assert.equal(rexKeys.size, Object.keys(bindings).length, "Duplicate resolved shortcut");
    const omni = readFileSync("modules/tools/omniwm.nix", "utf8");
    for (const [, binding] of omni.matchAll(/hotkey "([^"]+)"/g)) {
      if (binding === "Unassigned" || binding.includes("\${")) continue;
      assert(!rexKeys.has(normalise(binding)), `OmniWM conflict: ${binding}`);
    }
    // Generated OmniWM number bindings use Option or Control-Option, never Command.
    for (let number = 0; number <= 9; number++) {
      assert(!rexKeys.has(normalise(`Option+${number}`)));
      assert(!rexKeys.has(normalise(`Control+Option+${number}`)));
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
