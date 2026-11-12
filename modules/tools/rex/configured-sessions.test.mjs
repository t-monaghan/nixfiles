import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const rex = process.env.REX_BIN_DIR ? join(process.env.REX_BIN_DIR, "rex") : null;
const skip = !rex || !existsSync(rex) || !process.env.PI_SESSION_TEMP;

test("configured Rex sessions reuse Sesh settings", { skip }, () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-configured-test-"));
  try {
    const script = join(dir, "test.lua");
    writeFileSync(script, `
local actions, queued, calls = {}, {}, {}
local sessions = {
  { name = "dolomite", path = "~", startup_command = "ssh dolomite" },
  { name = "notes", path = "~/notes", startup_command = "nvim ~/notes/notes.md && exit" },
  { name = "nixfiles", path = "~/dev/nixfiles/", startup_command = "" },
  { name = "hud", path = "~/dev", startup_command = "/nix/store/hud-session/bin/hud-session && exit" },
}
local live, fail = {}, {}
local layer = {}
local terminal = { process = { foreground = { name = "fish", cwd = "/repo with spaces/src" } } }
local mock = {
  action = function(action) actions[action.name] = action.run end,
  client = { queue = function(action, args)
    if fail.select then error("selection failed") end
    assert(action == "session.select")
    queued[#queued + 1] = args.session_id
  end },
  call = function(method, args)
    if fail[method] then return nil, "API failed" end
    if method == "session.list" then return { sessions = live } end
    assert(method == "session.create")
    calls[#calls + 1] = args
    return { session_id = "new:" .. #calls }
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
  return { picker = "/nix/store/picker/bin/rex-session-picker", worktree_picker = "/nix/store/worktree-picker", sessions = sessions }
end }, { __index = _G })
local file = assert(io.open(${JSON.stringify(resolve("modules/tools/rex/configured-sessions.lua"))}, "r"))
local code = file:read("*a")
file:close()
setfenv(assert(loadstring(code)), env)()
local ctx = { client_id = "app:origin", session_id = "current" }
assert(actions.configured_sessions(ctx).layer_id == "picker")
assert(layer.args.focus and layer.args.bounds[3] == 0.8)
local options = layer.args.layout.block.options
assert(options.shell == "none")
assert(options.command[1] == "/nix/store/picker/bin/rex-session-picker")
assert(options.command[2] == ctx.client_id)
assert(#options.command == 6 and options.command[3] == "dolomite" and options.command[6] == "hud")
assert(not pcall(actions.configured_sessions, {}))
fail.layer = true
assert(not pcall(actions.configured_sessions, ctx))
fail.layer = nil

for index, session in ipairs(sessions) do
  local result = actions.open_configured_session(ctx, { name = session.name })
  assert(result.session_id == "new:" .. index and queued[index] == result.session_id)
  local request = calls[index]
  assert(request.label == session.name and #request.initial_windows == 1)
  options = request.initial_windows[1].layout.block.options
  assert(options.cwd == os.getenv("HOME") .. session.path:sub(2), "Unexpected cwd: " .. tostring(options.cwd))
  assert(options.initial_input == (session.startup_command ~= "" and session.startup_command .. "\\n" or nil), "Unexpected startup command")
end
live[1] = { label = "notes", session_id = "existing:notes" }
local reused = actions.open_configured_session(ctx, { name = "notes" }).session_id
assert(reused == "existing:notes", "Expected existing:notes, got " .. tostring(reused))
assert(#calls == 4 and queued[5] == "existing:notes")
assert(not pcall(actions.open_configured_session, {}, { name = "notes" }))
assert(not pcall(actions.open_configured_session, ctx, { name = "unknown" }))
live[2] = { label = "notes", session_id = "duplicate:notes" }
assert(not pcall(actions.open_configured_session, ctx, { name = "notes" }))
assert(#calls == 4 and #queued == 5)
live[1], live[2] = nil, nil
for _, method in ipairs({ "session.list", "session.create" }) do
  fail[method] = true
  assert(not pcall(actions.open_configured_session, ctx, { name = "notes" }))
  fail[method] = nil
end
fail.select = true
local ok, err = pcall(actions.open_configured_session, ctx, { name = "notes" })
assert(not ok and tostring(err):find("Session new:5 is available", 1, true), tostring(err))
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
local worktree = actions.open_worktree(ctx, { name = "repo #42", path = "/repo/.worktrees/feature" })
assert(worktree.session_id == "new:6")
assert(calls[6].initial_windows[1].layout.block.options.cwd == "/repo/.worktrees/feature")
assert(calls[6].initial_windows[1].layout.block.options.initial_input == nil)
live[1] = { label = "repo #42", session_id = "existing:worktree" }
assert(actions.open_worktree(ctx, { name = "repo #42", path = "/repo/.worktrees/feature" }).session_id == "existing:worktree")
assert(#calls == 6)
for index = #sessions, 1, -1 do sessions[index] = nil end
assert(not pcall(actions.configured_sessions, ctx))
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
