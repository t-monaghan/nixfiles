local function terminal(label, cwd)
  return {
    block = {
      flavor = "com.superlogical.terminal.shell",
      label = label,
      options = { cwd = cwd },
    },
  }
end

local created, err = rex.server("dolomite").call("session.create", {
  label = rex.args.name,
  initial_windows = {
    {
      window_label = "nixfiles + nxp",
      layout = {
        split = {
          direction = "horizontal",
          ratio = 0.5,
          before = terminal("nixfiles", rex.args.nixfiles or "/home/tom/nixfiles"),
          after = terminal("nxp", rex.args.nxp or "/home/tom/nxp"),
        },
      },
    },
  },
})
if not created then error(err, 0) end

if rex.args.select ~= false then
  local ok, select_err = pcall(rex.client.queue, "session.select", {
    session_id = created.session_id,
  })
  if not ok then
    error("Created " .. created.session_id .. " on dolomite, but could not select it: " .. tostring(select_err), 0)
  end
end

return created
