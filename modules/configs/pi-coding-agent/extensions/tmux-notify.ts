/**
 * Tmux Notify Extension
 *
 * Brackets the tmux session name when pi is waiting for input,
 * mirroring claude-code's tmux notification hooks.
 *
 * e.g. "work" becomes "[work]" when pi needs attention.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

function tmux(cmd: string): string | null {
	try {
		return execSync(`tmux ${cmd}`, {
			encoding: "utf8",
			timeout: 2000,
			stdio: ["pipe", "pipe", "pipe"],
		}).trim();
	} catch {
		return null;
	}
}

function bracketSession(): void {
	if (!process.env.TMUX) return;
	const session = tmux("display-message -p '#{session_name}'");
	if (!session || session.startsWith("[")) return;
	tmux(`set-environment -t ${JSON.stringify(session)} PI_ORIGINAL_SESSION ${JSON.stringify(session)}`);
	tmux(`rename-session -t ${JSON.stringify(session)} ${JSON.stringify(`[${session}]`)}`);
}

function unbracketSession(): void {
	if (!process.env.TMUX) return;
	const session = tmux("display-message -p '#{session_name}'");
	if (!session || !session.startsWith("[")) return;
	const envLine = tmux(`show-environment -t ${JSON.stringify(session)} PI_ORIGINAL_SESSION`);
	if (!envLine) return;
	const original = envLine.replace(/^[^=]*=/, "");
	if (!original) return;
	tmux(`set-environment -t ${JSON.stringify(session)} -u PI_ORIGINAL_SESSION`);
	tmux(`rename-session -t ${JSON.stringify(session)} ${JSON.stringify(original)}`);
}

export default function (pi: ExtensionAPI) {
	pi.on("turn_end", async () => bracketSession());
	pi.on("turn_start", async () => unbracketSession());
}
