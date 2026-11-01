local history = require("history")
local path = history.path()
local clients = history.read(path)

local function check(result, err)
  if not result then error(err, 0) end
  return result
end

local sessions = check(rex.call("session.list"))
local live = {}
for _, session in ipairs(sessions.sessions or {}) do
  live[session.session_id] = true
end
for _, recent in pairs(clients) do
  for index = #recent, 1, -1 do
    if not live[recent[index]] then table.remove(recent, index) end
  end
end

local connected = check(rex.call("client.list"))
for _, client in ipairs(connected.clients or {}) do
  if client.info and client.info.kind == "app" and #(client.session_ids or {}) == 1 then
    history.record(clients, client.client_id, client.session_ids[1])
  end
end
history.write(path, clients)

-- Rex emits attachment events, not an active-session event. A normal session
-- switch attaches the app to the selected session, including picker clicks.
rex.on("client_connected", function(ctx, ev)
  local result = check(rex.call("client.inspect", { client_id = ev.client_id }))
  if result.client.info and result.client.info.kind == "app" then
    history.record(clients, ev.client_id, ev.session_id or ctx.session_id)
    history.write(path, clients)
  end
end)

rex.on("session_destroyed", function(_, ev)
  history.remove(clients, ev.session_id)
  history.write(path, clients)
end)
