local history = require("history")
require("configured-sessions")

rex.action{
  name = "last_session",
  title = "Toggle Recent Session",
  category = "Session",
  run = function(ctx)
    if not ctx.client_id or not ctx.session_id then
      error("A Rex client and current session are required", 0)
    end
    local result, err = rex.call("session.list")
    if not result then error(err, 0) end
    local live = {}
    for _, session in ipairs(result.sessions or {}) do
      live[session.session_id] = true
    end
    local previous = history.previous(history.read(history.path()), ctx.client_id, ctx.session_id, live)
    if not previous then error("No recent session recorded; visit another session first", 0) end
    rex.client.queue("session.select", { session_id = previous })
  end,
}

local function bind(key, action, args)
  rex.bind("cmd+shift+" .. key, action, args)
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  bind(key, "pane.focus", { direction = direction })
  bind("ctrl+" .. key, "pane.resize", { direction = direction, amount = 5 })
end

bind("d", "pane.split", { direction = "right" })
bind("ctrl+d", "pane.split", { direction = "down" })
bind("z", "pane.zoom")
bind("x", "pane.close")

rex.bind("cmd+k", "client.palette.toggle")
rex.bind("cmd+shift+p", "session.switch")
rex.bind("cmd+w", "client.window.close")
rex.bind("alt+shift+[Slash]", "show_shortcuts")

bind("c", "client.tab.new")
bind("n", "client.tab.next")
bind(",", "client.tab.rename")
for index = 1, 9 do
  bind(tostring(index), "client.tab.goto", { index = index })
end

bind("s", "session.switch")
rex.bind("alt+shift+o", "configured_sessions")
rex.bind("alt+shift+p", "worktree_picker")
bind("a", "last_session")
rex.bind("ctrl+tab", "last_session")
bind("[BracketRight]", "session.next")
bind("[BracketLeft]", "session.previous")
bind("ctrl+n", "session.new")
rex.bind("cmd+r", "session.rename")
rex.bind("alt+shift+ctrl+w", "close_pr_session")
rex.bind("alt+shift+c", "reload_sessions")
bind("r", "client.config.reload")
