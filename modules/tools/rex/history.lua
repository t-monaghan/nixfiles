local history = {}

function history.path()
  local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  return state .. "/rex/session-history.json"
end

function history.read(path)
  local file = io.open(path, "r")
  if not file then return {} end
  local data = file:read("*a")
  file:close()
  local decoded = rex.json.decode(data)
  if type(decoded) ~= "table" then return {} end
  local clients = {}
  for client_id, sessions in pairs(decoded) do
    if type(client_id) == "string" and type(sessions) == "table" then
      clients[client_id] = {}
      for _, session_id in ipairs(sessions) do
        if type(session_id) == "string" then
          table.insert(clients[client_id], session_id)
        end
      end
    end
  end
  return clients
end

function history.record(clients, client_id, session_id)
  local sessions = clients[client_id] or {}
  for index = #sessions, 1, -1 do
    if sessions[index] == session_id then table.remove(sessions, index) end
  end
  table.insert(sessions, 1, session_id)
  clients[client_id] = sessions
end

function history.remove(clients, session_id)
  for _, sessions in pairs(clients) do
    for index = #sessions, 1, -1 do
      if sessions[index] == session_id then table.remove(sessions, index) end
    end
  end
end

function history.previous(clients, client_id, current, live)
  for _, session_id in ipairs(clients[client_id] or {}) do
    if session_id ~= current and live[session_id] then return session_id end
  end
end

function history.write(path, clients)
  local data, err = rex.json.encode(clients)
  if not data then error(err, 0) end
  local file, open_error = io.open(path .. ".new", "w")
  if not file then error(open_error, 0) end
  local written, write_error = file:write(data)
  local closed, close_error = file:close()
  if not written then error(write_error, 0) end
  if not closed then error(close_error, 0) end
  local renamed, rename_error = os.rename(path .. ".new", path)
  if not renamed then error(rename_error, 0) end
end

return history
