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

rex.action{
  name = "last_pane",
  title = "Toggle Recent Pane",
  category = "Pane",
  run = function(ctx)
    if not ctx.client_id or not ctx.session_id or not ctx.block_id then return end
    local server = ctx.server and rex.server(ctx.server) or rex
    -- Record the pane the client is showing before reversing server focus history.
    local focused, focus_err = server.call("session.focus_block", {
      session_id = ctx.session_id,
      block_id = ctx.block_id,
    })
    if not focused then error(focus_err, 0) end
    local result, err = server.call("focus_history.reverse")
    if not result then
      if err and err:find("method_not_found", 1, true) then
        error("Recent pane switching requires Rex Server API revision 19 or later", 0)
      end
      error(err, 0)
    end
    if result.reversed then
      rex.client.queue("session.select", { session_id = result.session_id, window_id = result.window_id })
    end
  end,
}

rex.action{
  name = "split_down_small",
  title = "Split Down (12 Rows)",
  category = "Pane",
  run = function(ctx)
    if not ctx.session_id or not ctx.block_id then
      error("A Rex session and focused block are required", 0)
    end
    local size, size_err = rex.call("com.superlogical.terminal.size", {
      session_id = ctx.session_id,
      block_id = ctx.block_id,
      args = {},
    })
    if not size then error(size_err, 0) end
    if not size.rows or size.rows < 2 then
      error("The focused terminal is too short to split", 0)
    end
    -- Allow one extra row for the new pane header.
    local ratio = 1 - math.min(13 / size.rows, 0.5)
    local result, err = rex.call("session.new_split", {
      session_id = ctx.session_id,
      anchor_id = ctx.block_id,
      direction = "vertical",
      side = "after",
      ratio = ratio,
      layout = { block = { flavor = "com.superlogical.terminal.shell" } },
      focus = true,
    })
    if not result then error(err, 0) end
    local resized, resize_err = rex.call("session.resize_pane", {
      session_id = ctx.session_id,
      direction = "vertical",
      before_block_id = ctx.block_id,
      after_block_id = result.block_ids[1],
      ratio = ratio,
    })
    if not resized then error(resize_err, 0) end
  end,
}

local function bind(key, action, args)
  rex.bind("cmd+shift+" .. key, action, args)
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  bind(key, "pane.focus", { direction = direction })
  bind("ctrl+" .. key, "pane.resize", { direction = direction, amount = 5 })
end

rex.bind("alt+u", "pane.split", { direction = "down" })
rex.bind("alt+i", "split_down_small")
rex.bind("alt+o", "pane.split", { direction = "right" })
bind("z", "pane.zoom")
bind("x", "pane.close")

rex.bind("ctrl+tab", "last_pane")
rex.bind("cmd+k", "pane.go_to")
rex.bind("cmd+[Period]", "pane.view_activity")
rex.bind("cmd+w", "client.window.close")
rex.bind("cmd+shift+f", "pi_kimi_popup")
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
bind("[BracketRight]", "session.next")
bind("[BracketLeft]", "session.previous")
bind("ctrl+n", "session.new")
rex.bind("cmd+r", "client.tab.rename")
rex.bind("alt+shift+ctrl+w", "close_pr_session")
rex.bind("alt+shift+c", "reload_sessions")
bind("r", "client.config.reload")
