import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const rex = process.env.REX_BIN_DIR ? join(process.env.REX_BIN_DIR, "rex") : null;
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

test("configured Rex sessions create, reuse, and order sessions", { skip }, () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-configured-test-"));
  try {
    const script = join(dir, "test.lua");
    writeFileSync(script, `
local actions, queued, calls, moves, attached = {}, {}, {}, {}, {}
local sessions = {
  { name = "hud", path = "~/dev", startup_command = "/nix/store/hud-session/bin/hud-session && exit" },
  { name = "notes", path = "~/notes", startup_command = "nvim ~/notes/notes.md && exit" },
  { name = "nixfiles", path = "~/dev/nixfiles/", startup_command = "" },
}
local live, fail = {}, {}
local layer = {}
local terminal = { process = { foreground = { name = "fish", cwd = "/repo with spaces/src" } } }
local mock = {
  action = function(action) actions[action.name] = action.run end,
  client = { queue = function(action, args)
    if fail.select then error("selection failed") end
    queued[#queued + 1] = { action = action, args = args }
  end },
  call = function(method, args)
    if fail[method] then return nil, "API failed: " .. method end
    if method == "session.list" then return { sessions = live } end
    if method == "session.create" then
      calls[#calls + 1] = args
      local id = "new:" .. #calls
      live[#live + 1] = { label = args.label, session_id = id }
      return { session_id = id }
    end
    if method == "session.attach" then
      attached[#attached + 1] = args.session_id
      return {}
    end
    if method == "session.move" then
      moves[#moves + 1] = args
      local moving
      for index, session in ipairs(live) do
        if session.session_id == args.session_id then moving = table.remove(live, index); break end
      end
      assert(moving, "Cannot move an unknown session")
      local target = #live + 1
      if args.before_session_id then
        target = nil
        for index, session in ipairs(live) do
          if session.session_id == args.before_session_id then target = index; break end
        end
      end
      assert(target, "Cannot find the session order anchor")
      table.insert(live, target, moving)
      return {}
    end
    error("Unexpected API call: " .. method)
  end,
  block = { call = function(creator, method, args)
    assert(creator == "com.superlogical.terminal" and method == "process")
    assert(args.block_id == "focused")
    if fail.process then return nil, "process failed" end
    return terminal.process
  end },
  session = { new_layer = function(args)
    if fail.layer then return nil, "layer failed" end
    layer.args = args
    return { layer_id = "picker" }
  end },
}
local env = setmetatable({ rex = mock, require = function(name)
  assert(name == "session-settings")
  return { worktree_picker = "/nix/store/worktree-picker", sessions = sessions }
end }, { __index = _G })
local file = assert(io.open(${JSON.stringify(resolve("modules/tools/rex/configured-sessions.lua"))}, "r"))
local code = file:read("*a")
file:close()
setfenv(assert(loadstring(code)), env)()
local ctx = { client_id = "app:origin", session_id = "current" }

for index, session in ipairs(sessions) do
  local result = actions.open_configured_session(ctx, { name = session.name })
  assert(result.session_id == "new:" .. index)
  assert(queued[index].action == "session.select" and queued[index].args.session_id == result.session_id)
  local request = calls[index]
  assert(request.label == session.name and #request.initial_windows == 1)
  local options = request.initial_windows[1].layout.block.options
  assert(options.cwd == os.getenv("HOME") .. session.path:sub(2), "Unexpected cwd: " .. tostring(options.cwd))
  assert(options.initial_input == (session.startup_command ~= "" and session.startup_command .. "\\n" or nil), "Unexpected startup command")
end
assert(#moves == 0, "Already ordered sessions must not move")
assert(actions.open_configured_session(ctx, { name = "notes" }).session_id == "new:2")
assert(#calls == 3 and queued[4].args.session_id == "new:2")
assert(not pcall(actions.open_configured_session, {}, { name = "notes" }))
assert(not pcall(actions.open_configured_session, ctx, { name = "unknown" }))
live[#live + 1] = { label = "notes", session_id = "duplicate:notes" }
assert(not pcall(actions.open_configured_session, ctx, { name = "notes" }))
assert(#calls == 3 and #queued == 4)
table.remove(live)

live[1], live[2], live[3], live[4], live[5] = live[3], { label = "repo #1", session_id = "other:1" }, live[1], { label = "repo #2", session_id = "other:2" }, live[2]
actions.configured_sessions(ctx)
assert(queued[#queued].action == "session.switch")
assert(#calls == 3 and #moves == 3 and #attached == 3)
for index = 1, 3 do assert(live[index].session_id == "new:" .. index) end
assert(live[4].session_id == "other:1" and live[5].session_id == "other:2")
actions.configured_sessions(ctx)
assert(#moves == 3 and #calls == 3, "Repeated use must reuse ordered sessions")
assert(not pcall(actions.configured_sessions, {}))
actions.reload_sessions(ctx)
assert(queued[#queued].action == "client.config.reload")
assert(not pcall(actions.reload_sessions, {}))

local remote = { name = "remote", path = "~", remote = true }
sessions[#sessions + 1] = remote
assert(actions.ensure_sessions({}, {}).ready)
assert(#calls == 3, "Local startup must not create remote sessions")
assert(actions.ensure_sessions({}, { include_remote = true }).ready)
assert(#calls == 4 and calls[4].initial_windows[1].layout.block.options.cwd == os.getenv("HOME"))
assert(live[4].label == "remote" and live[5].session_id == "other:1" and live[6].session_id == "other:2")
table.remove(sessions)
table.remove(live, 4)

for _, method in ipairs({ "session.list", "session.create" }) do
  fail[method] = true
  local ok, err = pcall(actions.open_worktree, ctx, { name = "missing", path = "/repo" })
  assert(not ok and tostring(err):find(method, 1, true), tostring(err))
  fail[method] = nil
end
for _, method in ipairs({ "session.attach", "session.move" }) do
  live[1], live[2] = live[2], live[1]
  fail[method] = true
  local ok, err = pcall(actions.configured_sessions, ctx)
  assert(not ok and tostring(err):find(method, 1, true), tostring(err))
  fail[method] = nil
  actions.configured_sessions(ctx)
end
fail.select = true
local ok, err = pcall(actions.open_configured_session, ctx, { name = "notes" })
assert(not ok and tostring(err):find("Session new:2 is available", 1, true), tostring(err))
fail.select = nil
assert(actions.worktree_picker(ctx).layer_id == "picker")
assert(layer.args.layout.block.options.command[1] == "/nix/store/worktree-picker")
assert(layer.args.layout.block.options.command[2] == ctx.client_id)
assert(not pcall(actions.worktree_picker, {}))
ctx.block_id = "focused"
assert(actions.worktree_picker(ctx).layer_id == "picker")
assert(layer.args.layout.block.options.command[3] == "/repo with spaces/src")
fail.process = true
actions.worktree_picker(ctx)
assert(#layer.args.layout.block.options.command == 2)
fail.process = nil
terminal.process = {}
actions.worktree_picker(ctx)
assert(#layer.args.layout.block.options.command == 2)
terminal.process = { child = { name = "fish", cwd = "/repo/.worktrees/pr-42/src" } }
actions.worktree_picker(ctx)
assert(layer.args.layout.block.options.command[3] == "/repo/.worktrees/pr-42/src")
terminal.process.foreground = { name = "ssh", cwd = "/local/repo" }
actions.worktree_picker(ctx)
assert(#layer.args.layout.block.options.command == 2)
terminal.process.foreground = { name = "fish" }
actions.worktree_picker(ctx)
assert(#layer.args.layout.block.options.command == 2)
assert(layer.args.focus and layer.args.bounds[3] == 0.8)
assert(layer.args.layout.block.options.shell == "none")
fail.layer = true
assert(not pcall(actions.worktree_picker, ctx))
fail.layer = nil
local worktree = actions.open_worktree(ctx, { name = "repo #42", path = "/repo/.worktrees/feature" })
assert(worktree.session_id == "new:5")
assert(calls[5].initial_windows[1].layout.block.options.cwd == "/repo/.worktrees/feature")
assert(calls[5].initial_windows[1].layout.block.options.initial_input == nil)
assert(actions.open_worktree(ctx, { name = "repo #42", path = "/repo/.worktrees/feature" }).session_id == worktree.session_id)
assert(#calls == 5)
for index = #sessions, 1, -1 do sessions[index] = nil end
actions.configured_sessions(ctx)
assert(queued[#queued].action == "session.switch", "An empty configuration must still open the native picker")
assert(#calls == 5)
return { ok = true }
`);
    const result = spawnSync(rex, ["--autostart=false", "do", script, "--json"], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(result.stdout), { ok: true });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

for (const status of [0, 1, 130, 2]) {
  test(`configured-session picker handles fzf status ${status}`, { skip: !process.env.PI_SESSION_TEMP }, () => {
    const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-picker-test-"));
    try {
      writeFileSync(join(dir, "fzf"), `#!/bin/bash\n/bin/cat >/dev/null\nprintf '%s\\n' 'notes with spaces'\nexit ${status}\n`, { mode: 0o755 });
      writeFileSync(join(dir, "rex"), `#!/bin/bash\nprintf '%s\\n' "$@"\n`, { mode: 0o755 });
      const result = spawnSync("bash", ["-euo", "pipefail", "modules/tools/rex/pick-session.sh", "client:origin", "notes with spaces", "dolomite"], {
        encoding: "utf8",
        env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, FZF_DEFAULT_OPTS: "" },
      });
      assert.equal(result.status, status === 2 ? 2 : 0, result.stderr);
      assert.equal(result.stdout, status === 0
        ? "--autostart=false\n--client\nclient:origin\ndo\nopen_configured_session\nname=notes with spaces\n"
        : "");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
