/**
 * spawn-worktree — fork a background pi agent into a fresh git worktree.
 *
 * Combines worktrunk (`wt`) for worktree creation with tmux for a detached,
 * attachable session. The spawned `pi` runs in interactive mode inside a
 * detached tmux session at the worktree path, so you can attach later with
 * `sesh connect pi-<branch>` (or `tmux attach -t pi-<branch>`) to inspect,
 * steer, or follow up.
 *
 * Surfaces:
 *   /spawn <branch> <task...>                 (slash command, you type it)
 *   spawn_worktree({ branch, task, ... })     (LLM tool, the agent calls it)
 *
 * Requirements: `wt` and `tmux` on PATH. (tmux-notify.ts will bracket the
 * session name when the background pi is waiting for input.)
 */

import { spawn, spawnSync } from "node:child_process";
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
	sessionName?: string;
}

interface SpawnResult {
	sessionName: string;
	worktreePath: string;
	created: boolean;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function which(cmd: string): boolean {
	const r = spawnSync("sh", ["-c", `command -v ${cmd}`], { stdio: "ignore" });
	return r.status === 0;
}

function sanitizeForTmux(name: string): string {
	// tmux session names can't contain '.' or ':'. Replace anything that's
	// not [A-Za-z0-9_-] with '-' and collapse runs.
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

function tmuxSessionExists(name: string): boolean {
	const r = spawnSync("tmux", ["has-session", "-t", `=${name}`], { stdio: "ignore" });
	return r.status === 0;
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

function spawnDetached(sessionName: string, worktreePath: string, task: string, model?: string): void {
	// Pass pi args separately so tmux exec's them directly (no shell parsing).
	const piArgs: string[] = [];
	if (model) piArgs.push("--model", model);
	piArgs.push(task);

	const child = spawn(
		"tmux",
		["new-session", "-d", "-s", sessionName, "-c", worktreePath, "pi", ...piArgs],
		{ detached: true, stdio: "ignore", env: process.env },
	);
	child.unref();
}

async function spawnWorktree(opts: SpawnOptions, ctx: ExtensionContext): Promise<SpawnResult> {
	if (!which("wt")) throw new Error("`wt` (worktrunk) not found on PATH");
	if (!which("tmux")) throw new Error("`tmux` not found on PATH");
	if (!isValidBranchName(opts.branch)) throw new Error(`Invalid branch name: ${JSON.stringify(opts.branch)}`);
	if (!opts.task.trim()) throw new Error("Task is required");

	const sessionName = opts.sessionName ?? `pi-${sanitizeForTmux(opts.branch)}`;
	if (!sessionName) throw new Error("Could not derive a valid tmux session name");
	if (tmuxSessionExists(sessionName)) {
		throw new Error(
			`tmux session '${sessionName}' already exists; attach with \`sesh connect ${sessionName}\` ` +
				`or kill with \`tmux kill-session -t ${sessionName}\``,
		);
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

	spawnDetached(sessionName, worktreePath, opts.task, opts.model);
	return { sessionName, worktreePath, created };
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
	sessionName: Type.Optional(
		Type.String({ description: "Override tmux session name (default: 'pi-<sanitized-branch>')." }),
	),
});

const spawnWorktreeTool = defineTool({
	name: "spawn_worktree",
	label: "Spawn worktree agent",
	description: [
		"Spawn an independent pi agent in a new git worktree, running in a detached tmux session.",
		"Use for parallel/independent work that should NOT share this conversation's context.",
		"The spawned agent runs in interactive mode and can be attached later via `sesh connect <session>`.",
	].join(" "),
	promptSnippet: "spawn_worktree: fork an independent pi agent into a fresh git worktree (background tmux session).",
	parameters: SpawnParams,
	async execute(_id, params, _signal, _onUpdate, ctx) {
		try {
			const r = await spawnWorktree(params, ctx);
			const lines = [
				`${r.created ? "Created" : "Reused"} worktree for branch '${params.branch}' at ${r.worktreePath}`,
				`Spawned background pi in tmux session '${r.sessionName}'.`,
				`Attach with: sesh connect ${r.sessionName}   (or: tmux attach -t ${r.sessionName})`,
			];
			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { sessionName: r.sessionName, worktreePath: r.worktreePath, created: r.created },
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
		description: "Spawn a background pi agent in a new worktree (usage: /spawn <branch> <task>)",
		handler: async (args: string, ctx: ExtensionCommandContext) => {
			const { branch, task } = parseSlashArgs(args);
			if (!branch || !task) {
				ctx.ui.notify("Usage: /spawn <branch> <task>", "warning");
				return;
			}
			try {
				const r = await spawnWorktree({ branch, task }, ctx);
				ctx.ui.notify(
					`spawned ${r.sessionName} → ${r.worktreePath} (attach: sesh connect ${r.sessionName})`,
					"info",
				);
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				ctx.ui.notify(`/spawn failed: ${msg}`, "error");
			}
		},
	});
}
