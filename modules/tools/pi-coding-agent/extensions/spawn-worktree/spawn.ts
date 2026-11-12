import { spawnSync } from "node:child_process";
import { parseWorktrees, type WtWorktree } from "../worktrunk/output.ts";

interface SpawnOptions {
	branch: string;
	task: string;
	baseBranch?: string;
	model?: string;
	paneName?: string;
	sessionName?: string;
	windowName?: string;
}

export interface WorktreeReplacement {
	sessionId: string;
	blockId: string;
	paneName: string;
	worktreePath: string;
	created: boolean;
	piArgs: string[];
}

function which(cmd: string): boolean {
	return spawnSync("bash", ["-c", `command -v ${cmd}`], { stdio: "ignore" }).status === 0;
}

function isValidBranchName(branch: string): boolean {
	if (!branch || branch.length > 200) return false;
	if (/[\s\\'"`$;&|<>(){}\[\]\n\r]/.test(branch)) return false;
	return !branch.startsWith("-");
}

function listWorktrees(cwd: string): WtWorktree[] {
	const r = spawnSync("wt", ["-C", cwd, "list", "--format", "json"], { encoding: "utf-8" });
	if (r.status !== 0) throw new Error(`wt list failed: ${r.stderr || r.stdout || `exit ${r.status}`}`);
	try {
		return parseWorktrees(r.stdout);
	} catch (err) {
		throw new Error(`wt list returned invalid JSON output: ${(err as Error).message}`);
	}
}

function createWorktree(cwd: string, branch: string, baseBranch?: string): void {
	// `-x true` creates the worktree without opening another interactive shell.
	const args = ["-C", cwd, "switch", "-c", branch];
	if (baseBranch) args.push("-b", baseBranch);
	args.push("-x", "true");
	const r = spawnSync("wt", args, { encoding: "utf-8" });
	if (r.status !== 0) throw new Error(`wt switch -c ${branch} failed: ${r.stderr || r.stdout || `exit ${r.status}`}`);
}

export function prepareWorktree(opts: SpawnOptions, ctx: { cwd: string }): WorktreeReplacement {
	for (const command of ["wt", "rex", "pi"]) {
		if (!which(command)) throw new Error(`\`${command}\` not found on PATH`);
	}
	if (typeof process.execve !== "function") throw new Error("This Node version cannot replace the current pi process");
	const sessionId = process.env.REX_SESSION;
	const blockId = process.env.REX_BLOCK;
	if (!sessionId || !blockId) throw new Error("Run spawn_worktree inside a Rex pane");
	if (!isValidBranchName(opts.branch)) throw new Error(`Invalid branch name: ${JSON.stringify(opts.branch)}`);
	if (!opts.task.trim()) throw new Error("Task is required");

	const paneName = opts.paneName ?? opts.sessionName ?? opts.windowName ?? opts.branch.split("/").at(-1)!.slice(0, 40);
	if (!paneName.trim() || paneName.length > 40 || /[\x00-\x1f\x7f]/.test(paneName)) {
		throw new Error("Rex pane name must contain 1–40 characters without control characters");
	}
	const inspect = spawnSync("rex", ["--autostart=false", "block", "inspect", "-s", sessionId, blockId, "--json"], { encoding: "utf-8" });
	if (inspect.status !== 0) throw new Error(`Cannot inspect the current Rex pane: ${inspect.stderr || inspect.stdout || inspect.error?.message}`);

	const existing = listWorktrees(ctx.cwd).find((w) => w.branch === opts.branch);
	let worktreePath = existing?.path;
	if (!worktreePath) {
		createWorktree(ctx.cwd, opts.branch, opts.baseBranch);
		worktreePath = listWorktrees(ctx.cwd).find((w) => w.branch === opts.branch)?.path;
		if (!worktreePath) throw new Error(`Created worktree for '${opts.branch}' but it did not appear in wt list`);
	}

	const rename = spawnSync("rex", ["--autostart=false", "block", "rename", "-s", sessionId, blockId, paneName], { encoding: "utf-8" });
	if (rename.status !== 0) throw new Error(`Cannot rename the current Rex pane: ${rename.stderr || rename.stdout || rename.error?.message}`);

	const prompt = [
		"You are a worktree agent in a fresh pi session. Complete the task without routine follow-up questions.",
		"Use repository conventions and record reasonable assumptions. Ask only when missing information or approval is critical to safe, correct work.",
		"For implementation tasks, make the changes, run appropriate verification, commit, push the branch, and create or update a draft PR unless the task says otherwise. Do not merge it.",
		"In personal repositories that rarely use PRs, follow the repository workflow instead; do not create a PR just to satisfy this default.",
		"Report verification results and the draft PR URL, or explain why no PR was created. If blocked, report the blocker rather than guessing.",
		"",
		opts.task,
	].join("\n");
	return {
		sessionId, blockId, paneName, worktreePath, created: !existing,
		piArgs: opts.model ? ["--model", opts.model, prompt] : [prompt],
	};
}

export function replaceProcess(replacement: WorktreeReplacement): void {
	process.chdir(replacement.worktreePath);
	const env = Object.fromEntries(Object.entries(process.env).filter((entry): entry is [string, string] => entry[1] !== undefined));
	env.PWD = replacement.worktreePath;
	// Run after pi restores the terminal. exec preserves the pane's PTY and process ID.
	process.execve!("/bin/bash", ["bash", "-c", 'exec pi "$@"', "pi", ...replacement.piArgs], env);
}

export function scheduleReplacement(replacement: WorktreeReplacement, shutdown: () => void): void {
	const onExit = (code: number) => {
		if (code === 0) replaceProcess(replacement);
	};
	process.once("exit", onExit);
	try {
		shutdown();
	} catch (err) {
		process.removeListener("exit", onExit);
		throw err;
	}
}
