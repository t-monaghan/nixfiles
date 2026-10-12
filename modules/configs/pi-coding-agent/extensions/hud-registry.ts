import { spawnSync } from "node:child_process";
import { mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const state = join(process.env.XDG_STATE_HOME || join(homedir(), ".local/state"), "pi-hud", "active");
const record = join(state, `${process.pid}.json`);

function pane(): { socket: string; paneId: string; windowId: string; sessionId: string } | undefined {
	if (!process.stdin.isTTY || !process.stdout.isTTY || !process.env.TMUX || !process.env.TMUX_PANE) return;
	const socket = process.env.TMUX.split(",")[0];
	const result = spawnSync("tmux", ["-S", socket, "display-message", "-p", "-t", process.env.TMUX_PANE, "#{pane_id}\t#{window_id}\t#{session_id}"], { encoding: "utf8" });
	if (result.status !== 0) return;
	const [paneId, windowId, sessionId] = result.stdout.trim().split("\t");
	if (!paneId?.startsWith("%") || !windowId?.startsWith("@") || !sessionId?.startsWith("$")) return;
	return { socket, paneId, windowId, sessionId };
}

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | undefined;
	let working = false;
	const tmux = pane();
	const update = (ctx: ExtensionContext) => {
		mkdirSync(state, { recursive: true, mode: 0o700 });
		const temp = `${record}.tmp`;
		writeFileSync(temp, JSON.stringify({
			pid: process.pid,
			file: ctx.sessionManager.getSessionFile(),
			id: ctx.sessionManager.getSessionId(),
			cwd: ctx.cwd,
			name: ctx.sessionManager.getSessionName(),
			mode: ctx.mode,
			working,
			heartbeat: Date.now(),
			tmux,
		}), { mode: 0o600 });
		renameSync(temp, record);
	};
	pi.on("session_start", async (_event, ctx) => {
		update(ctx);
		if (timer) clearInterval(timer);
		timer = setInterval(() => update(ctx), 15000);
		timer.unref();
	});
	pi.on("session_info_changed", async (_event, ctx) => update(ctx));
	pi.on("session_before_switch", async () => { rmSync(record, { force: true }); });
	pi.on("agent_start", async (_event, ctx) => { working = true; update(ctx); });
	pi.on("agent_settled", async (_event, ctx) => { working = false; update(ctx); });
	pi.on("session_shutdown", async () => {
		if (timer) clearInterval(timer);
		rmSync(record, { force: true });
	});
}
