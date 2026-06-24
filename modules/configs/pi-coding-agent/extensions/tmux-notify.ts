/**
 * Tmux Notify Extension
 *
 * Brackets the tmux session name when pi is waiting for input,
 * mirroring claude-code's tmux notification hooks.
 *
 * e.g. "work" becomes "[work]" when pi needs attention.
 *
 * Two cases trigger the "needs attention" state:
 *  1. The agent finished a turn and is waiting for input (`turn_end`).
 *  2. The agent is mid-run and pi opens a blocking prompt — e.g. a
 *     pi-sandbox permission request, a trust prompt, or a destructive
 *     confirmation. pi has no dedicated "permission requested" event, but
 *     every such prompt goes through the shared `ctx.ui` dialog methods
 *     (`select` / `confirm` / `input` / `custom` / `editor`). We wrap those
 *     once on the shared UI object so any extension's prompt (including
 *     pi-sandbox) brackets the session and rings the bell.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
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

/** Ring the terminal bell so unfocused terminals surface an urgency hint. */
function ringBell(): void {
	try {
		process.stdout.write("\x07");
	} catch {
		// ignore
	}
}

/**
 * Blocking, user-attention dialog methods on the shared `ctx.ui` object.
 * When the agent is running and one of these is invoked, pi is blocked
 * waiting for the user to grant/deny something (e.g. a sandbox permission
 * request), so we treat it like "needs attention".
 */
const PROMPT_METHODS = ["select", "confirm", "input", "custom", "editor"] as const;
const WRAPPED_FLAG = "__piTmuxNotifyWrapped";

export default function (pi: ExtensionAPI) {
	let agentBusy = false;
	let pendingPrompts = 0;

	function onPromptOpen(): void {
		if (pendingPrompts++ === 0) {
			bracketSession();
			ringBell();
		}
	}

	function onPromptClose(): void {
		if (pendingPrompts > 0 && --pendingPrompts === 0) {
			unbracketSession();
		}
	}

	// Wrap the shared UI dialog methods once. `ctx.ui` is the same object for
	// every extension, so this also intercepts prompts raised by pi-sandbox.
	function ensureUiWrapped(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		const ui = ctx.ui as unknown as Record<string, unknown> & { [WRAPPED_FLAG]?: boolean };
		if (ui[WRAPPED_FLAG]) return;
		ui[WRAPPED_FLAG] = true;

		for (const name of PROMPT_METHODS) {
			const original = ui[name];
			if (typeof original !== "function") continue;
			const orig = original as (...args: unknown[]) => unknown;
			ui[name] = async (...args: unknown[]) => {
				// Only treat a prompt as an interruption when the agent is mid-run.
				// User-initiated menus (e.g. /model) open while idle and shouldn't notify.
				const interrupt = agentBusy;
				if (interrupt) onPromptOpen();
				try {
					return await orig.apply(ui, args);
				} finally {
					if (interrupt) onPromptClose();
				}
			};
		}
	}

	pi.on("session_start", async (_event, ctx) => ensureUiWrapped(ctx));

	pi.on("agent_start", async () => {
		agentBusy = true;
	});
	pi.on("agent_end", async () => {
		agentBusy = false;
	});

	pi.on("turn_end", async () => bracketSession());
	pi.on("turn_start", async () => unbracketSession());
	pi.on("session_shutdown", async () => unbracketSession());
}
