/**
 * spawn-worktree — fork a background pi agent into a fresh git worktree.
 *
 * Combines worktrunk (`wt`) for worktree creation with a detached tmux window
 * in the current session. The spawned `pi` runs interactively in the worktree.
 *
 * Surfaces:
 *   /spawn <branch> <task...>                 (slash command, you type it)
 *   spawn_worktree({ branch, task, ... })     (LLM tool, the agent calls it)
 *
 * Requirements: `wt` and `tmux` on PATH, running inside tmux.
 */

import { spawnSync } from "node:child_process";
import { Type } from "@mariozechner/pi-ai";
import {
	defineTool,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type ExtensionContext,
} from "@mariozechner/pi-coding-agent";

// ─── Types ──────────────────────────────────────────────────────────────────

interface WtWorktree {
	branch: string;
	path: string;
	kind: string;
	is_main?: boolean;
}

interface SpawnOptions {
	branch: string;
	task: string;
	baseBranch?: string;
	model?: string;
	windowName?: string;
}

interface SpawnResult {
	windowId: string;
	windowName: string;
	worktreePath: string;
	created: boolean;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function which(cmd: string): boolean {
	const r = spawnSync("sh", ["-c", `command -v ${cmd}`], { stdio: "ignore" });
	return r.status === 0;
}

function sanitizeForTmux(name: string): string {
	// Keep the generated window name free of tmux target separators.
	return name.replace(/[^A-Za-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "");
}

function isValidBranchName(branch: string): boolean {
	// Lenient git-ref-ish check + reject shell metacharacters defensively.
	if (!branch || branch.length > 200) return false;
	if (/[\s\\'"`$;&|<>(){}\[\]\n\r]/.test(branch)) return false;
	if (branch.startsWith("-")) return false;
	return true;
}

function listWorktrees(cwd: string): WtWorktree[] {
	const r = spawnSync("wt", ["-C", cwd, "list", "--format", "json"], {
		encoding: "utf-8",
	});
	if (r.status !== 0) {
		throw new Error(`wt list failed: ${r.stderr || r.stdout || `exit ${r.status}`}`);
	}
	try {
		const parsed = JSON.parse(r.stdout) as unknown;
		if (!Array.isArray(parsed)) return [];
		return parsed.filter((w): w is WtWorktree => {
			return typeof w === "object" && w !== null
				&& typeof (w as WtWorktree).branch === "string"
				&& typeof (w as WtWorktree).path === "string";
		});
	} catch (err) {
		throw new Error(`wt list returned non-JSON: ${(err as Error).message}`);
	}
}

function currentSessionId(): string {
	if (!process.env.TMUX || !process.env.TMUX_PANE) {
		throw new Error("Run spawn_worktree inside a tmux pane");
	}
	const r = spawnSync("tmux", ["display-message", "-p", "-t", process.env.TMUX_PANE, "#{session_id}"], {
		encoding: "utf-8",
	});
	if (r.status !== 0 || !r.stdout.trim()) {
		throw new Error(`Could not find the current tmux session: ${r.stderr || r.stdout || `exit ${r.status}`}`);
	}
	return r.stdout.trim();
}

function existingWindow(sessionId: string, name: string): string | undefined {
	const r = spawnSync("tmux", ["list-windows", "-t", sessionId, "-F", "#{window_id}\t#{window_name}"], {
		encoding: "utf-8",
	});
	if (r.status !== 0) throw new Error(`tmux list-windows failed: ${r.stderr || `exit ${r.status}`}`);
	return r.stdout.split("\n").find((line) => line.split("\t")[1] === name)?.split("\t")[0];
}

function createWorktree(cwd: string, branch: string, baseBranch?: string): void {
	// `wt switch -x <cmd>` replaces the wt process with <cmd> after creating
	// the worktree, so `-x true` is the clean "create and exit" pattern.
	const args = ["-C", cwd, "switch", "-c", branch];
	if (baseBranch) args.push("-b", baseBranch);
	args.push("-x", "true");
	const r = spawnSync("wt", args, { encoding: "utf-8" });
	if (r.status !== 0) {
		throw new Error(`wt switch -c ${branch} failed: ${r.stderr || r.stdout || `exit ${r.status}`}`);
	}
}

function spawnWindow(sessionId: string, windowName: string, worktreePath: string, task: string, model?: string): string {
	const piArgs = model ? ["--model", model, task] : [task];
	const r = spawnSync(
		"tmux",
		["new-window", "-d", "-P", "-F", "#{window_id}", "-t", `${sessionId}:`, "-n", windowName, "-c", worktreePath, "pi", ...piArgs],
		{ encoding: "utf-8" },
	);
	if (r.status !== 0 || !r.stdout.trim()) {
		throw new Error(`tmux new-window failed: ${r.stderr || r.stdout || `exit ${r.status}`}`);
	}
	return r.stdout.trim();
}

async function spawnWorktree(opts: SpawnOptions, ctx: ExtensionContext): Promise<SpawnResult> {
	if (!which("wt")) throw new Error("`wt` (worktrunk) not found on PATH");
	if (!which("tmux")) throw new Error("`tmux` not found on PATH");
	if (!isValidBranchName(opts.branch)) throw new Error(`Invalid branch name: ${JSON.stringify(opts.branch)}`);
	if (!opts.task.trim()) throw new Error("Task is required");

	const sessionId = currentSessionId();
	const windowName = opts.windowName ?? `pi-${sanitizeForTmux(opts.branch)}`;
	if (!windowName || /[:\n\r]/.test(windowName)) throw new Error("Invalid tmux window name");
	const occupied = existingWindow(sessionId, windowName);
	if (occupied) {
		throw new Error(`tmux window '${windowName}' already exists (${occupied}); select it with \`tmux select-window -t ${occupied}\``);
	}

	const existing = listWorktrees(ctx.cwd).find((w) => w.branch === opts.branch);
	let created = false;
	let worktreePath: string;
	if (existing) {
		worktreePath = existing.path;
	} else {
		createWorktree(ctx.cwd, opts.branch, opts.baseBranch);
		created = true;
		const after = listWorktrees(ctx.cwd).find((w) => w.branch === opts.branch);
		if (!after) {
			throw new Error(`Created worktree for '${opts.branch}' but it didn't show up in \`wt list\``);
		}
		worktreePath = after.path;
	}

	const windowId = spawnWindow(sessionId, windowName, worktreePath, opts.task, opts.model);
	return { windowId, windowName, worktreePath, created };
}

// ─── Extension ──────────────────────────────────────────────────────────────

const SpawnParams = Type.Object({
	branch: Type.String({
		description: "Git branch name for the new worktree. Created if missing.",
	}),
	task: Type.String({
		description: "Prompt/task to pass to the spawned pi agent as its first message.",
	}),
	baseBranch: Type.Optional(
		Type.String({ description: "Base branch for `wt switch -c -b <base>`. Defaults to repo default branch." }),
	),
	model: Type.Optional(
		Type.String({ description: "Pi model pattern (e.g. 'claude-opus-4-7'). Defaults to user setting." }),
	),
	windowName: Type.Optional(
		Type.String({ description: "Override tmux window name (default: 'pi-<sanitized-branch>')." }),
	),
});

const spawnWorktreeTool = defineTool({
	name: "spawn_worktree",
	label: "Spawn worktree agent",
	description: [
		"Spawn an independent pi agent in a new git worktree, running in a detached window of the current tmux session.",
		"Use for parallel/independent work that should NOT share this conversation's context.",
		"Requires a tmux pane. Select the returned window ID to inspect or steer the interactive agent.",
	].join(" "),
	promptSnippet: "spawn_worktree: fork an independent pi agent into a fresh git worktree (background tmux window in the current session).",
	parameters: SpawnParams,
	async execute(_id, params, _signal, _onUpdate, ctx) {
		try {
			const r = await spawnWorktree(params, ctx);
			const lines = [
				`${r.created ? "Created" : "Reused"} worktree for branch '${params.branch}' at ${r.worktreePath}`,
				`Spawned background pi in tmux window '${r.windowName}' (${r.windowId}).`,
				`Select with: tmux select-window -t ${r.windowId}`,
			];
			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { windowId: r.windowId, windowName: r.windowName, worktreePath: r.worktreePath, created: r.created },
			};
		} catch (err) {
			const msg = err instanceof Error ? err.message : String(err);
			return {
				content: [{ type: "text", text: `spawn_worktree failed: ${msg}` }],
				details: { error: msg },
				isError: true,
			};
		}
	},
});

function parseSlashArgs(raw: string): { branch?: string; task?: string } {
	const trimmed = raw.trim();
	if (!trimmed) return {};
	const idx = trimmed.indexOf(" ");
	if (idx === -1) return { branch: trimmed };
	return { branch: trimmed.slice(0, idx), task: trimmed.slice(idx + 1).trim() };
}

export default function (pi: ExtensionAPI) {
	pi.registerTool(spawnWorktreeTool);

	pi.registerCommand("spawn", {
		description: "Spawn a background pi agent in a new tmux window (usage: /spawn <branch> <task>)",
		handler: async (args: string, ctx: ExtensionCommandContext) => {
			const { branch, task } = parseSlashArgs(args);
			if (!branch || !task) {
				ctx.ui.notify("Usage: /spawn <branch> <task>", "warning");
				return;
			}
			try {
				const r = await spawnWorktree({ branch, task }, ctx);
				ctx.ui.notify(
					`spawned ${r.windowName} (${r.windowId}) → ${r.worktreePath} (select: tmux select-window -t ${r.windowId})`,
					"info",
				);
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				ctx.ui.notify(`/spawn failed: ${msg}`, "error");
			}
		},
	});
}
