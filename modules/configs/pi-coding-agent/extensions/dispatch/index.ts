import { spawn, spawnSync, type ChildProcess } from "node:child_process";
import {
	closeSync,
	createReadStream,
	existsSync,
	mkdirSync,
	openSync,
	readFileSync,
	realpathSync,
	renameSync,
	writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { createInterface } from "node:readline";
import { randomUUID } from "node:crypto";
import { Type } from "@mariozechner/pi-ai";
import {
	defineTool,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type ExtensionContext,
} from "@mariozechner/pi-coding-agent";

interface DispatchConfig {
	agentRoot: string;
	repoRoot: string;
	model: string;
	maxConcurrent: number;
}

type JobState = "running" | "completed" | "failed" | "cancelled";

interface UsageStats {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	turns: number;
}

interface DispatchJob {
	id: string;
	repo: string;
	branch: string;
	base: string;
	task: string;
	model: string;
	worktreePath: string;
	sessionDir: string;
	eventsFile: string;
	stderrFile: string;
	exitFile: string;
	pid: number;
	state: JobState;
	createdAt: string;
	completedAt?: string;
	exitCode?: number;
	completionNotified: boolean;
	finalOutput?: string;
	toolCalls?: string[];
	usage?: UsageStats;
	summary?: string;
}

interface WtWorktree {
	branch?: string;
	path?: string;
}

const DEFAULT_CONFIG: DispatchConfig = {
	agentRoot: join(homedir(), "dev", "agents"),
	repoRoot: join(homedir(), "dev"),
	model: "github-copilot/kimi-k3",
	maxConcurrent: 5,
};
const POLL_INTERVAL_MS = 2000;
const MAX_FINAL_OUTPUT_BYTES = 30 * 1024;
const MAX_TOOL_CALLS = 30;

function expandHome(value: string): string {
	return value === "~" ? homedir() : value.startsWith("~/") ? join(homedir(), value.slice(2)) : value;
}

function canonicalPath(value: string): string {
	const absolute = resolve(value);
	try {
		return realpathSync.native(absolute);
	} catch {
		return absolute;
	}
}

function loadConfig(): DispatchConfig {
	const configPath = join(getAgentDir(), "dispatch.json");
	try {
		const parsed = JSON.parse(readFileSync(configPath, "utf8")) as Partial<DispatchConfig>;
		return {
			agentRoot: canonicalPath(expandHome(parsed.agentRoot ?? DEFAULT_CONFIG.agentRoot)),
			repoRoot: canonicalPath(expandHome(parsed.repoRoot ?? DEFAULT_CONFIG.repoRoot)),
			model: parsed.model?.trim() || DEFAULT_CONFIG.model,
			maxConcurrent: Math.max(1, Math.min(10, parsed.maxConcurrent ?? DEFAULT_CONFIG.maxConcurrent)),
		};
	} catch {
		return DEFAULT_CONFIG;
	}
}

function isInside(parent: string, child: string): boolean {
	const rel = relative(parent, child);
	return rel === "" || (!rel.startsWith(`..${sep}`) && rel !== "..");
}

function command(command: string, args: string[], cwd?: string): string {
	const result = spawnSync(command, args, {
		cwd,
		encoding: "utf8",
		maxBuffer: 10 * 1024 * 1024,
	});
	if (result.status !== 0) {
		throw new Error(`${command} failed: ${(result.stderr || result.stdout || `exit ${result.status}`).trim()}`);
	}
	return result.stdout.trim();
}

function tryCommand(commandName: string, args: string[], cwd?: string): string | undefined {
	const result = spawnSync(commandName, args, { cwd, encoding: "utf8", maxBuffer: 10 * 1024 * 1024 });
	return result.status === 0 ? result.stdout.trim() : undefined;
}

function listWorktrees(repoPath: string): WtWorktree[] {
	const output = command("wt", ["-C", repoPath, "list", "--format", "json"]);
	const parsed = JSON.parse(output) as unknown;
	return Array.isArray(parsed) ? (parsed as WtWorktree[]) : [];
}

function validateBranch(branch: string): void {
	if (/^pr:\d+$/.test(branch)) return;
	const result = spawnSync("git", ["check-ref-format", "--branch", branch], { stdio: "ignore" });
	if (result.status !== 0) throw new Error(`Invalid branch name: ${JSON.stringify(branch)}`);
}

function resolveRepo(config: DispatchConfig, repo: string): string {
	if (!repo.trim()) throw new Error("Repository name is required");
	const repoPath = canonicalPath(resolve(config.repoRoot, repo));
	if (!isInside(config.repoRoot, repoPath) || repoPath === config.repoRoot) {
		throw new Error(`Repository must be below ${config.repoRoot}`);
	}
	if (!existsSync(join(repoPath, ".git"))) throw new Error(`Repository not found: ${repoPath}`);
	return repoPath;
}

function defaultBase(repoPath: string): string {
	const remoteHead = tryCommand("git", ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], repoPath);
	if (remoteHead) return remoteHead;
	for (const candidate of ["main", "master"]) {
		if (spawnSync("git", ["show-ref", "--verify", "--quiet", `refs/heads/${candidate}`], { cwd: repoPath }).status === 0) {
			return candidate;
		}
	}
	return "HEAD";
}

function parseWtPath(output: string): string | undefined {
	for (const line of output.split("\n").reverse()) {
		try {
			const value = JSON.parse(line) as { path?: unknown };
			if (typeof value.path === "string") return value.path;
		} catch {
			// Worktrunk hooks can write non-JSON progress lines.
		}
	}
	return undefined;
}

function prepareWorktree(
	config: DispatchConfig,
	repoPath: string,
	branch: string,
	base?: string,
): { path: string; created: boolean; base: string } {
	validateBranch(branch);
	const existing = listWorktrees(repoPath).find((worktree) => worktree.branch === branch && worktree.path);
	const resolvedBase = base?.trim() || defaultBase(repoPath);
	if (existing?.path) return { path: existing.path, created: false, base: resolvedBase };

	const isShortcut = /^pr:\d+$/.test(branch);
	const localBranch = !isShortcut
		&& spawnSync("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], { cwd: repoPath }).status === 0;
	const remoteBranch = !isShortcut
		&& spawnSync("git", ["show-ref", "--verify", "--quiet", `refs/remotes/origin/${branch}`], { cwd: repoPath }).status === 0;
	const wtArgs = ["switch"];
	if (!isShortcut && !localBranch && !remoteBranch) wtArgs.push("--create");
	wtArgs.push(branch);
	if (!isShortcut && !localBranch && !remoteBranch && base) wtArgs.push("--base", base);
	wtArgs.push("--no-cd", "--format", "json");

	const fishScript = "set -gx WT_WORKTREE_ROOT $argv[1]; cd $argv[2]; wt $argv[3..-1]";
	const output = command("fish", ["-c", fishScript, "--", join(config.agentRoot, "worktrees"), repoPath, ...wtArgs]);
	const outputPath = parseWtPath(output);
	if (outputPath) return { path: outputPath, created: true, base: resolvedBase };

	const after = listWorktrees(repoPath);
	const found = after.find((worktree) => worktree.branch === branch && worktree.path);
	if (!found?.path) throw new Error(`Worktrunk created '${branch}' but returned no worktree path`);
	return { path: found.path, created: true, base: resolvedBase };
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	if (currentScript && !currentScript.startsWith("/$bunfs/root/") && existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const executable = basename(process.execPath).toLowerCase();
	return /^(node|bun)(\.exe)?$/.test(executable)
		? { command: "pi", args }
		: { command: process.execPath, args };
}

function shellQuote(value: string): string {
	return `'${value.replaceAll("'", "'\\''")}'`;
}

function saveJobs(registryPath: string, jobs: Map<string, DispatchJob>): void {
	mkdirSync(dirname(registryPath), { recursive: true });
	const temp = `${registryPath}.tmp`;
	writeFileSync(temp, `${JSON.stringify([...jobs.values()], null, 2)}\n`, "utf8");
	renameSync(temp, registryPath);
}

function loadJobs(registryPath: string): Map<string, DispatchJob> {
	try {
		const parsed = JSON.parse(readFileSync(registryPath, "utf8")) as DispatchJob[];
		return new Map(parsed.map((job) => [job.id, job]));
	} catch {
		return new Map();
	}
}

function readExitCode(exitFile: string): number | undefined {
	try {
		const value = JSON.parse(readFileSync(exitFile, "utf8")) as { exitCode?: unknown };
		return typeof value.exitCode === "number" ? value.exitCode : undefined;
	} catch {
		return undefined;
	}
}

function processExists(pid: number): boolean {
	if (pid <= 0) return false;
	try {
		process.kill(pid, 0);
		return true;
	} catch {
		return false;
	}
}

function primaryArgument(args: Record<string, unknown>): string {
	for (const key of ["path", "file_path", "command", "query", "pattern"]) {
		if (typeof args[key] === "string") {
			const value = args[key] as string;
			return value.length > 100 ? `${value.slice(0, 100)}…` : value;
		}
	}
	return "";
}

async function parseEvents(eventsFile: string): Promise<{
	finalOutput: string;
	toolCalls: string[];
	usage: UsageStats;
}> {
	const usage: UsageStats = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
	const toolCalls: string[] = [];
	let finalOutput = "";
	if (!existsSync(eventsFile)) return { finalOutput, toolCalls, usage };

	const lines = createInterface({ input: createReadStream(eventsFile, "utf8"), crlfDelay: Infinity });
	for await (const line of lines) {
		let event: any;
		try {
			event = JSON.parse(line);
		} catch {
			continue;
		}
		if (event.type === "tool_execution_start" && toolCalls.length < MAX_TOOL_CALLS) {
			const arg = primaryArgument(event.args ?? {});
			toolCalls.push(`${event.toolName}${arg ? `: ${arg}` : ""}`);
		}
		if (event.type !== "message_end" || event.message?.role !== "assistant") continue;
		usage.turns += 1;
		usage.input += event.message.usage?.input ?? 0;
		usage.output += event.message.usage?.output ?? 0;
		usage.cacheRead += event.message.usage?.cacheRead ?? 0;
		usage.cacheWrite += event.message.usage?.cacheWrite ?? 0;
		usage.cost += event.message.usage?.cost?.total ?? 0;
		const text = (event.message.content ?? [])
			.filter((part: any) => part.type === "text")
			.map((part: any) => part.text)
			.join("\n");
		if (text) finalOutput = text;
	}
	if (Buffer.byteLength(finalOutput, "utf8") > MAX_FINAL_OUTPUT_BYTES) {
		finalOutput = `${finalOutput.slice(0, MAX_FINAL_OUTPUT_BYTES)}\n\n[Output truncated. See ${eventsFile}]`;
	}
	return { finalOutput, toolCalls, usage };
}

function readFailureOutput(stderrFile: string): string {
	try {
		const stderr = readFileSync(stderrFile, "utf8").trim();
		return stderr.length > MAX_FINAL_OUTPUT_BYTES
			? `${stderr.slice(-MAX_FINAL_OUTPUT_BYTES)}\n\n[Earlier stderr omitted. See ${stderrFile}]`
			: stderr;
	} catch {
		return "";
	}
}

function gitSummary(job: DispatchJob): string {
	const status = tryCommand("git", ["status", "--short"], job.worktreePath) || "(clean)";
	const diffStat = tryCommand("git", ["diff", "--stat", `${job.base}...HEAD`], job.worktreePath) || "(no committed diff)";
	const commits = tryCommand("git", ["log", "--oneline", `${job.base}..HEAD`], job.worktreePath) || "(no commits)";
	return [`Status:\n${status}`, `Diff stat (${job.base}...HEAD):\n${diffStat}`, `Commits:\n${commits}`].join("\n\n");
}

function formatUsage(usage: UsageStats): string {
	return `${usage.turns} turns, ${usage.input} input, ${usage.output} output, ${usage.cacheRead} cache read, $${usage.cost.toFixed(4)}`;
}

function formatCompletion(job: DispatchJob): string {
	const resume = `cd ${shellQuote(job.worktreePath)}; and pi --session-dir ${shellQuote(job.sessionDir)} --continue`;
	return [
		`Worktree agent ${job.id} ${job.state}.`,
		`Repository: ${job.repo}`,
		`Branch: ${job.branch}`,
		`Worktree: ${job.worktreePath}`,
		`Model: ${job.model}`,
		job.usage ? `Usage: ${formatUsage(job.usage)}` : undefined,
		job.toolCalls?.length ? `Tool calls (${job.toolCalls.length} shown):\n${job.toolCalls.map((call) => `- ${call}`).join("\n")}` : "Tool calls: none",
		job.summary,
		`Agent result:\n${job.finalOutput || "(no assistant output)"}`,
		`Resume:\n${resume}`,
	].filter(Boolean).join("\n\n");
}

function formatJobs(jobs: Map<string, DispatchJob>): string {
	if (jobs.size === 0) return "No worktree agents have been dispatched from this session.";
	return [...jobs.values()]
		.sort((a, b) => b.createdAt.localeCompare(a.createdAt))
		.map((job) => `${job.id}\t${job.state}\t${job.repo}\t${job.branch}\t${job.model}`)
		.join("\n");
}

function startAgent(job: DispatchJob): ChildProcess {
	mkdirSync(job.sessionDir, { recursive: true });
	const stdout = openSync(job.eventsFile, "a");
	const stderr = openSync(job.stderrFile, "a");
	const prompt = [
		"You are an asynchronous worktree agent. Complete the task in the current repository.",
		"Do not ask for follow-up input. Make the changes, run appropriate verification, and report the result.",
		"Do not remove the worktree.",
		"",
		job.task,
	].join("\n");
	const args = [
		"--mode", "json", "--print", "--approve",
		"--model", job.model, "--thinking", "low",
		"--session-dir", job.sessionDir,
		"--name", `${job.repo}:${job.branch}`,
		prompt,
	];
	const invocation = getPiInvocation(args);
	const wrapper = [
		'set +e',
		'"$@"',
		'code=$?',
		'tmp="$PI_DISPATCH_EXIT_FILE.tmp"',
		'printf \'{"exitCode":%s}\\n\' "$code" > "$tmp"',
		'mv "$tmp" "$PI_DISPATCH_EXIT_FILE"',
		'exit "$code"',
	].join("\n");
	const child = spawn("/bin/sh", ["-c", wrapper, "dispatch-agent", invocation.command, ...invocation.args], {
		cwd: job.worktreePath,
		detached: true,
		stdio: ["ignore", stdout, stderr],
		env: { ...process.env, PI_DISPATCH_EXIT_FILE: job.exitFile, PI_DISPATCH_JOB: job.id },
	});
	closeSync(stdout);
	closeSync(stderr);
	child.unref();
	return child;
}

const DispatchParams = Type.Object({
	repo: Type.String({ description: "Repository name or path relative to ~/dev." }),
	branch: Type.String({ description: "Existing or new branch name, or a pr:N Worktrunk shortcut." }),
	task: Type.String({ description: "Complete task for the asynchronous worktree agent." }),
	base: Type.Optional(Type.String({ description: "Base branch when creating a new branch." })),
	model: Type.Optional(Type.String({ description: "Pi model override. Defaults to the configured cheap model." })),
});

export default function (pi: ExtensionAPI) {
	const config = loadConfig();
	let jobs = new Map<string, DispatchJob>();
	let registryPath = "";
	let timer: NodeJS.Timeout | undefined;
	let activeContext: ExtensionContext | undefined;
	let registered = false;
	const finishing = new Set<string>();

	const save = () => {
		if (registryPath) saveJobs(registryPath, jobs);
	};

	const updateStatus = () => {
		const running = [...jobs.values()].filter((job) => job.state === "running").length;
		activeContext?.ui.setStatus("dispatch", running > 0 ? `${running} agent${running === 1 ? "" : "s"}` : undefined);
	};

	const complete = async (job: DispatchJob, exitCode: number) => {
		if (job.state !== "running" || finishing.has(job.id)) return;
		finishing.add(job.id);
		try {
			job.exitCode = exitCode;
			job.completedAt = new Date().toISOString();
			job.state = exitCode === 0 ? "completed" : "failed";
			const parsed = await parseEvents(job.eventsFile);
			job.finalOutput = parsed.finalOutput || (exitCode === 0 ? "" : readFailureOutput(job.stderrFile));
			job.toolCalls = parsed.toolCalls;
			job.usage = parsed.usage;
			job.summary = gitSummary(job);
			save();
			updateStatus();
			if (!activeContext || job.completionNotified) return;
			try {
				pi.sendMessage(
					{
						customType: "dispatch-completion",
						content: formatCompletion(job),
						display: true,
						details: { jobId: job.id, sessionDir: job.sessionDir, worktreePath: job.worktreePath },
					},
					{ deliverAs: "followUp", triggerTurn: true },
				);
				job.completionNotified = true;
				save();
			} catch {
				// A resumed dispatcher retries the notification from the persisted job.
			}
		} finally {
			finishing.delete(job.id);
		}
	};

	const poll = async () => {
		for (const job of jobs.values()) {
			if (job.state !== "running") continue;
			const exitCode = readExitCode(job.exitFile);
			if (exitCode !== undefined) await complete(job, exitCode);
			else if (!processExists(job.pid)) await complete(job, 1);
		}
		for (const job of jobs.values()) {
			if (job.state !== "running" && !job.completionNotified && activeContext) {
				try {
					pi.sendMessage(
						{ customType: "dispatch-completion", content: formatCompletion(job), display: true },
						{ deliverAs: "followUp", triggerTurn: true },
					);
					job.completionNotified = true;
					save();
				} catch {
					break;
				}
			}
		}
	};

	const registerSurfaces = () => {
		if (registered) return;
		registered = true;
		pi.registerTool(defineTool({
			name: "dispatch_worktree_agent",
			label: "Dispatch worktree agent",
			description: "Create or reuse a Worktrunk worktree in the shared agent directory and start a persistent asynchronous pi agent. The result returns immediately. Use /agents to inspect jobs.",
			promptSnippet: "dispatch_worktree_agent: run an asynchronous isolated pi agent in a named repository worktree.",
			promptGuidelines: ["Use dispatch_worktree_agent for independent repository work that can run asynchronously."],
			parameters: DispatchParams,
			async execute(_id, params) {
				const running = [...jobs.values()].filter((job) => job.state === "running").length;
				if (running >= config.maxConcurrent) throw new Error(`Concurrency limit reached (${config.maxConcurrent})`);
				if (!params.task.trim()) throw new Error("Task is required");
				const repoPath = resolveRepo(config, params.repo);
				const worktree = prepareWorktree(config, repoPath, params.branch, params.base);
				const id = `${Date.now().toString(36)}-${randomUUID().slice(0, 6)}`;
				const jobDir = join(config.agentRoot, "sessions", activeContext!.sessionManager.getSessionId(), id);
				mkdirSync(jobDir, { recursive: true });
				const job: DispatchJob = {
					id,
					repo: params.repo,
					branch: params.branch,
					base: worktree.base,
					task: params.task,
					model: params.model?.trim() || config.model,
					worktreePath: worktree.path,
					sessionDir: join(jobDir, "session"),
					eventsFile: join(jobDir, "events.jsonl"),
					stderrFile: join(jobDir, "stderr.log"),
					exitFile: join(jobDir, "exit.json"),
					pid: 0,
					state: "running",
					createdAt: new Date().toISOString(),
					completionNotified: false,
				};
				const child = startAgent(job);
				if (!child.pid) throw new Error("Failed to start the worktree agent process");
				job.pid = child.pid;
				jobs.set(job.id, job);
				save();
				updateStatus();
				child.once("error", async () => complete(job, 1));
				return {
					content: [{
						type: "text",
						text: `${worktree.created ? "Created" : "Reused"} ${job.worktreePath}\nStarted asynchronous agent ${job.id} with PID ${job.pid}. Use /agents to inspect it.`,
					}],
					details: { jobId: job.id, worktreePath: job.worktreePath, sessionDir: job.sessionDir },
				};
			},
		}));

		pi.registerCommand("agents", {
			description: "List, show, or cancel asynchronous worktree agents",
			handler: async (args: string, ctx: ExtensionCommandContext) => {
				const [action, id] = args.trim().split(/\s+/, 2);
				if (!action) {
					ctx.ui.notify(formatJobs(jobs), "info");
					return;
				}
				const job = jobs.get(action === "show" || action === "cancel" ? id : action);
				if (!job) {
					ctx.ui.notify("Usage: /agents [show|cancel] <job-id>", "warning");
					return;
				}
				if (action === "cancel") {
					if (job.state !== "running") {
						ctx.ui.notify(`${job.id} is ${job.state}.`, "warning");
						return;
					}
					try {
						process.kill(-job.pid, "SIGTERM");
					} catch {
						// The process can exit between the state check and the signal.
					}
					job.state = "cancelled";
					job.completedAt = new Date().toISOString();
					job.completionNotified = true;
					save();
					updateStatus();
					ctx.ui.notify(`Cancelled ${job.id}.`, "info");
					return;
				}
				ctx.ui.notify(job.finalOutput ? formatCompletion(job) : JSON.stringify(job, null, 2), "info");
			},
		});
	};

	pi.on("session_start", async (_event, ctx) => {
		if (canonicalPath(ctx.cwd) !== config.agentRoot) return;
		activeContext = ctx;
		const sessionRoot = join(config.agentRoot, "sessions", ctx.sessionManager.getSessionId());
		registryPath = join(sessionRoot, "jobs.json");
		mkdirSync(sessionRoot, { recursive: true });
		jobs = loadJobs(registryPath);
		registerSurfaces();
		updateStatus();
		await poll();
		timer = setInterval(() => void poll(), POLL_INTERVAL_MS);
		timer.unref();
	});

	pi.on("session_shutdown", async () => {
		if (timer) clearInterval(timer);
		timer = undefined;
		activeContext = undefined;
	});
}
