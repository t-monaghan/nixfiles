import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const rex = process.env.REX_BIN_DIR ? join(process.env.REX_BIN_DIR, "rex") : null;
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

test("Rex dolomite session script", { skip }, () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-dolomite-test-"));
  try {
    const script = join(dir, "test.lua");
    writeFileSync(script, `
local file = assert(io.open(${JSON.stringify(resolve("modules/tools/rex/dolomite.lua"))}, "r"))
local code = file:read("*a")
file:close()
local calls, queued, request = 0, 0, nil
local failure = { create = false, select = false }
local args = {}
local mock = {
  args = args,
  server = function(label)
    assert(label == "dolomite")
    return { call = function(method, params)
      assert(method == "session.create")
      calls = calls + 1
      request = params
      if failure.create then return nil, "connection failed" end
      return { session_id = "session:new-" .. calls }
    end }
  end,
  client = { queue = function(action, params)
    if failure.select then error("no client") end
    queued = queued + 1
    assert(action == "session.select")
    assert(params.session_id == "session:new-" .. calls)
  end },
}
local env = setmetatable({ rex = mock }, { __index = _G })
local function run()
  return setfenv(assert(loadstring(code)), env)()
end
assert(run().session_id == "session:new-1")
assert(queued == 1 and request.label == nil)
assert(#request.initial_windows == 1)
local split = request.initial_windows[1].layout.split
assert(split.direction == "horizontal" and split.ratio == 0.5)
assert(split.before.block.flavor == "com.superlogical.terminal.shell")
assert(split.after.block.flavor == "com.superlogical.terminal.shell")
assert(split.before.block.label == "nixfiles" and split.after.block.label == "nxp")
assert(split.before.block.options.cwd == "/home/tom/nixfiles")
assert(split.after.block.options.cwd == "/home/tom/nxp")
assert(run().session_id == "session:new-2", "Each run must create a new session")
args.name, args.nixfiles, args.nxp = "work", "/projects/nix files", "/projects/nxp"
args.select = false
run()
assert(queued == 2 and request.label == "work")
split = request.initial_windows[1].layout.split
assert(split.before.block.options.cwd == args.nixfiles)
assert(split.after.block.options.cwd == args.nxp)
args.select = true
failure.create = true
local ok, err = pcall(run)
assert(not ok and tostring(err):find("connection failed", 1, true))
assert(queued == 2)
failure.create, failure.select = false, true
ok, err = pcall(run)
assert(not ok and tostring(err):find("Created session:new-5 on dolomite", 1, true), tostring(err))
return { ok = true }
`);
    const result = spawnSync(rex, ["--autostart=false", "do", script, "--json"], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(result.stdout), { ok: true });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
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
local mock = {
  json = json,
  bind = function(key, action, args)
    assert(not bindings[key], "Duplicate binding: " .. key)
    bindings[key] = { action = action, args = args }
  end,
  action = function(action) actions[action.name] = action.run end,
  client = { queue = function(action, args) queued.action = action; queued.args = args end },
  on = function(event, handler) handlers[event] = handler end,
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
env.require = function(name) assert(name == "history"); return history end
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
assert(bindings["cmd+shift+a"].action == "last_session")
assert(bindings["cmd+shift+ctrl+j"].action == "pane.resize")
assert(bindings["cmd+shift+j"].args.direction == "down")
assert(bindings["cmd+shift+ctrl+d"].args.direction == "down")
assert(bindings["cmd+shift+ctrl+n"].action == "session.new")
for key in pairs(bindings) do
  assert(key:find("cmd+shift+", 1, true) == 1 and not key:find(">", 1, true))
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
    assert.equal(Object.keys(bindings).length, 32);

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
