local settings = require("session-settings")

local function select_session(session_id)
  local ok, err = pcall(rex.client.queue, "session.select", { session_id = session_id })
  if not ok then error("Session " .. session_id .. " is available, but selection failed: " .. tostring(err), 0) end
  return { session_id = session_id }
end

local function call(method, args)
  local result, err = rex.call(method, args)
  if not result then error(err, 0) end
  return result
end

local function list_sessions()
  return call("session.list").sessions or {}
end

local function order_sessions()
  local live = list_sessions()
  local fixed, desired, known = {}, {}, {}
  for _, configured in ipairs(settings.sessions) do
    for _, session in ipairs(live) do
      if session.label == configured.name then
        if known[configured.name] then
          error("Multiple Rex sessions named " .. configured.name .. "; rename one first", 0)
        end
        known[configured.name] = true
        fixed[#fixed + 1] = session.session_id
        desired[#desired + 1] = session.session_id
      end
    end
  end
  local anchor
  for _, session in ipairs(live) do
    if not known[session.label] then
      anchor = anchor or session.session_id
      desired[#desired + 1] = session.session_id
    end
  end
  local ordered = true
  for index, session in ipairs(live) do
    if session.session_id ~= desired[index] then ordered = false; break end
  end
  if ordered then return end
  for index = #fixed, 1, -1 do
    call("session.attach", { session_id = fixed[index] })
    call("session.move", { session_id = fixed[index], before_session_id = anchor })
    anchor = fixed[index]
  end
end

local function ensure_session(configured)
  local result
  local live = list_sessions()
  local existing
  for _, session in ipairs(live) do
    if session.label == configured.name then
      if existing then error("Multiple Rex sessions named " .. configured.name .. "; rename one first", 0) end
      existing = session.session_id
    end
  end
  if existing then return existing end

  local path = configured.path
  local home = os.getenv("HOME")
  if path == "~" then path = home
  elseif path:sub(1, 2) == "~/" then path = home .. path:sub(2) end
  local options = { cwd = path }
  if configured.startup_command and configured.startup_command ~= "" then
    options.initial_input = configured.startup_command .. "\n"
  end
  result = call("session.create", {
    label = configured.name,
    initial_windows = { {
      window_label = configured.name,
      layout = configured.layout or { block = { flavor = "com.superlogical.terminal.shell", options = options } },
    } },
  })
  return result.session_id
end

local function open_session(ctx, configured)
  if not ctx.client_id then error("A Rex client is required", 0) end
  local session_id = ensure_session(configured)
  order_sessions()
  return select_session(session_id)
end

local function ensure_sessions(include_remote)
  for _, configured in ipairs(settings.sessions) do
    if include_remote or not configured.remote then ensure_session(configured) end
  end
  order_sessions()
end

rex.action{
  name = "ensure_sessions",
  title = "Ensure Configured Sessions",
  category = "Session",
  args = { include_remote = "boolean?" },
  run = function(_, args)
    ensure_sessions(args.include_remote == true)
    return { ready = true }
  end,
}

rex.action{
  name = "reload_sessions",
  title = "Reload Configuration and Ensure Local Sessions",
  category = "Session",
  run = function(ctx)
    if not ctx.client_id then error("A Rex client is required", 0) end
    ensure_sessions(false)
    rex.client.queue("client.config.reload")
  end,
}

rex.action{
  name = "close_pr_session",
  title = "Close PR / Worktree Session",
  category = "Session",
  run = function(ctx)
    if not ctx.client_id or not ctx.session_id then
      error("A Rex client and current session are required", 0)
    end
    for _, session in ipairs(list_sessions()) do
      if session.session_id == ctx.session_id then
        for _, configured in ipairs(settings.sessions) do
          if session.label == configured.name then error("Cannot close configured session " .. session.label, 0) end
        end
        if not session.label:match("^.+ #%d+$") and not session.label:match("^.+: .+$") then
          error("Not a PR / worktree session: " .. session.label, 0)
        end
        return call("session.destroy", { session_id = ctx.session_id })
      end
    end
    error("Current session was not found", 0)
  end,
}

local function picker(ctx, command)
  if not ctx.client_id or not ctx.session_id then
    error("A Rex client and current session are required", 0)
  end
  local result, err = rex.session.new_layer{
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = { block = {
      flavor = "com.superlogical.terminal.shell",
      options = { shell = "none", command = command },
    } },
  }
  if not result then error(err, 0) end
  return result
end

rex.action{
  name = "show_shortcuts",
  title = "Show Configured Shortcuts",
  category = "Keys",
  run = function(ctx)
    return picker(ctx, { settings.shortcuts_popup })
  end,
}

rex.action{
  name = "open_configured_session",
  title = "Open Configured Session",
  category = "Session",
  args = { name = "string" },
  run = function(ctx, args)
    for _, session in ipairs(settings.sessions) do
      if session.name == args.name then return open_session(ctx, session) end
    end
    error("Unknown configured session: " .. args.name, 0)
  end,
}

rex.action{
  name = "configured_sessions",
  title = "Ensure Configured Sessions and Change Session",
  category = "Session",
  run = function(ctx)
    if not ctx.client_id then error("A Rex client is required", 0) end
    ensure_sessions(true)
    rex.client.queue("session.switch")
  end,
}

rex.action{
  name = "open_worktree",
  title = "Open Worktree Session",
  category = "Session",
  args = { name = "string", path = "string" },
  run = function(ctx, args)
    return open_session(ctx, { name = args.name, path = args.path })
  end,
}

rex.action{
  name = "worktree_picker",
  title = "Worktree / PR Picker",
  category = "Session",
  run = function(ctx)
    local command = { settings.worktree_picker, ctx.client_id }
    if ctx.block_id then
      local result = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
      local process = result and (result.foreground or result.child)
      if process and process.cwd and process.cwd:sub(1, 1) == "/"
        and process.name ~= "ssh" and process.name ~= "mosh-client" then
        command[#command + 1] = process.cwd
      end
    end
    return picker(ctx, command)
  end,
}
