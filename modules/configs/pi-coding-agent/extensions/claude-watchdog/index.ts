/**
 * claude-watchdog Pi extension
 *
 * Port of temikus/claude-watchdog for pi. Runs a critical post-mortem on
 * sessions automatically (via agent_end) or on-demand (via /analyze-session).
 *
 * Shared analyzer prompt: ./session-analyzer.md
 * (sourced from claude-watchdog/agents/session-analyzer.md — keep in sync,
 *  or wire via Nix symlink/copy at build time)
 *
 * Respects the same CLAUDE_WATCHDOG_* environment variables as the original.
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

// ─── Configuration (same env vars as upstream claude-watchdog) ───────────────

const DISABLED = process.env.CLAUDE_WATCHDOG_DISABLED === "1";
const MIN_TOOL_USES = parseInt(process.env.CLAUDE_WATCHDOG_MIN_TOOL_USES ?? "8", 10);
const COOLDOWN_SECONDS = parseInt(process.env.CLAUDE_WATCHDOG_COOLDOWN_SECONDS ?? "600", 10);
const ANALYSES_DIR = process.env.CLAUDE_WATCHDOG_ANALYSES_DIR ?? path.join(os.homedir(), ".claude/logs/claude-watchdog-analyses");
const LOG_FILE = process.env.CLAUDE_WATCHDOG_LOG ?? path.join(os.homedir(), ".claude/logs/claude-watchdog.log");
const MAX_ANALYSES = 20;
const MAX_TRANSCRIPT_CHARS = 50000;

// ─── State ──────────────────────────────────────────────────────────────────

let lastAnalysisTime = 0;

// ─── Helpers ────────────────────────────────────────────────────────────────

function log(message: string) {
	try {
		const dir = path.dirname(LOG_FILE);
		if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
		const line = `[${new Date().toISOString()}] [pi-ext] ${message}\n`;
		fs.appendFileSync(LOG_FILE, line);
	} catch {
		// Best-effort logging
	}
}

function shouldSkip(cwd: string): string | null {
	if (DISABLED) return "disabled via CLAUDE_WATCHDOG_DISABLED";
	if (fs.existsSync(path.join(cwd, ".claude-watchdog-skip"))) return "skip file present";
	const elapsed = (Date.now() - lastAnalysisTime) / 1000;
	if (COOLDOWN_SECONDS > 0 && elapsed < COOLDOWN_SECONDS) return `cooldown (${Math.round(COOLDOWN_SECONDS - elapsed)}s remaining)`;
	return null;
}

function countToolCalls(entries: any[]): number {
	let count = 0;
	for (const entry of entries) {
		if (entry.type === "message" && entry.message?.role === "assistant") {
			for (const part of entry.message.content ?? []) {
				if (part.type === "toolCall") count++;
			}
		}
	}
	return count;
}

function condenseTranscript(entries: any[]): string {
	const lines: string[] = [];

	for (const entry of entries) {
		if (entry.type !== "message") continue;
		const msg = entry.message;
		if (!msg) continue;

		if (msg.role === "user") {
			for (const part of msg.content ?? []) {
				if (part.type === "text") lines.push(`USER: ${part.text}`);
			}
		} else if (msg.role === "assistant") {
			for (const part of msg.content ?? []) {
				if (part.type === "text") lines.push(`ASSISTANT: ${part.text}`);
				else if (part.type === "toolCall") {
					const argsStr = JSON.stringify(part.arguments ?? {});
					const truncArgs = argsStr.length > 200 ? argsStr.slice(0, 200) + "..." : argsStr;
					lines.push(`TOOL_USE: ${part.name} ${truncArgs}`);
				}
			}
		} else if (msg.role === "toolResult") {
			const content = msg.content ?? [];
			for (const part of content) {
				if (part.type === "text") {
					const truncResult = part.text.length > 500 ? part.text.slice(0, 500) + "...[truncated]" : part.text;
					const errorPrefix = msg.isError ? "[ERROR] " : "";
					lines.push(`TOOL_RESULT: ${errorPrefix}${truncResult}`);
				}
			}
		}
	}

	// Weighted truncation: keep more recent context
	let transcript = lines.join("\n");
	if (transcript.length > MAX_TRANSCRIPT_CHARS) {
		// Keep last 80% of allowed size from the end (recent), 20% from the start
		const headSize = Math.floor(MAX_TRANSCRIPT_CHARS * 0.2);
		const tailSize = MAX_TRANSCRIPT_CHARS - headSize - 50; // 50 for separator
		transcript = transcript.slice(0, headSize) + "\n\n... [transcript truncated] ...\n\n" + transcript.slice(-tailSize);
	}

	return transcript;
}

function pruneAnalyses() {
	try {
		if (!fs.existsSync(ANALYSES_DIR)) return;
		const files = fs.readdirSync(ANALYSES_DIR)
			.filter(f => f.endsWith(".md"))
			.map(f => ({ name: f, mtime: fs.statSync(path.join(ANALYSES_DIR, f)).mtimeMs }))
			.sort((a, b) => b.mtime - a.mtime);

		for (const file of files.slice(MAX_ANALYSES)) {
			fs.unlinkSync(path.join(ANALYSES_DIR, file.name));
		}
	} catch {
		// Best-effort cleanup
	}
}

async function runAnalysis(cwd: string, transcript: string, signal?: AbortSignal): Promise<string> {
	const analyzerPrompt = fs.readFileSync(path.join(__dirname, "session-analyzer.md"), "utf-8");

	// Write transcript to temp file
	const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "watchdog-"));
	const transcriptFile = path.join(tmpDir, "transcript.txt");
	fs.writeFileSync(transcriptFile, transcript, { mode: 0o600 });

	try {
		const task = [
			`Analyze this coding session. The condensed transcript is at: ${transcriptFile}`,
			`The working directory is: ${cwd}`,
			`Read the transcript file first, then run git commands in the working directory.`,
		].join("\n");

		const args = [
			"--mode", "json",
			"-p",
			"--no-session",
			"--no-extensions",
			"--no-skills",
			"--no-prompt-templates",
			"--no-context-files",
			"--model", "sonnet",
			"--thinking", "off",
			"--tools", "read,bash,grep,find",
			"--system-prompt", analyzerPrompt,
			task,
		];

		return await new Promise<string>((resolve, reject) => {
			const piPath = process.argv[1];
			const invocation = piPath && fs.existsSync(piPath)
				? { command: process.execPath, args: [piPath, ...args] }
				: { command: "pi", args };

			const proc = spawn(invocation.command, invocation.args, {
				cwd,
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
			});

			let buffer = "";
			let lastAssistantText = "";

			proc.stdout.on("data", (data) => {
				buffer += data.toString();
				const lines = buffer.split("\n");
				buffer = lines.pop() || "";
				for (const line of lines) {
					if (!line.trim()) continue;
					try {
						const event = JSON.parse(line);
						if (event.type === "message_end" && event.message?.role === "assistant") {
							for (const part of event.message.content ?? []) {
								if (part.type === "text") lastAssistantText = part.text;
							}
						}
					} catch { /* skip non-JSON lines */ }
				}
			});

			proc.stderr.on("data", () => { /* discard */ });

			proc.on("close", (code) => {
				if (buffer.trim()) {
					try {
						const event = JSON.parse(buffer);
						if (event.type === "message_end" && event.message?.role === "assistant") {
							for (const part of event.message.content ?? []) {
								if (part.type === "text") lastAssistantText = part.text;
							}
						}
					} catch { /* ignore */ }
				}
				if (lastAssistantText) resolve(lastAssistantText);
				else reject(new Error(`Analyzer exited with code ${code} and no output`));
			});

			proc.on("error", reject);

			if (signal) {
				const kill = () => {
					proc.kill("SIGTERM");
					setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
				};
				if (signal.aborted) kill();
				else signal.addEventListener("abort", kill, { once: true });
			}
		});
	} finally {
		try { fs.unlinkSync(transcriptFile); } catch { /* ignore */ }
		try { fs.rmdirSync(tmpDir); } catch { /* ignore */ }
	}
}

function persistAnalysis(result: string, sessionId?: string) {
	try {
		if (!fs.existsSync(ANALYSES_DIR)) fs.mkdirSync(ANALYSES_DIR, { recursive: true });
		const timestamp = new Date().toISOString().replace(/[:.]/g, "").slice(0, 15) + "Z";
		const prefix = sessionId ? `${sessionId}-` : "";
		const filename = `${prefix}${timestamp}.md`;
		fs.writeFileSync(path.join(ANALYSES_DIR, filename), result, { mode: 0o600 });
		pruneAnalyses();
		log(`WROTE: ${filename}`);
	} catch (e: any) {
		log(`ERROR persisting analysis: ${e.message}`);
	}
}

// ─── Extension ──────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	// Automatic analysis on agent_end
	pi.on("agent_end", async (event, ctx) => {
		const skipReason = shouldSkip(ctx.cwd);
		if (skipReason) {
			log(`SKIP: ${skipReason}`);
			return;
		}

		const entries = ctx.sessionManager.getEntries();
		const toolCalls = countToolCalls(entries);

		if (toolCalls < MIN_TOOL_USES) {
			log(`SKIP: only ${toolCalls} tool calls (min: ${MIN_TOOL_USES})`);
			return;
		}

		const transcript = condenseTranscript(entries);
		if (!transcript.trim()) {
			log("SKIP: empty transcript");
			return;
		}

		log(`TRIGGER: ${toolCalls} tool calls, running analysis...`);
		lastAnalysisTime = Date.now();

		// Run analysis in the background (don't block the agent)
		runAnalysis(ctx.cwd, transcript)
			.then((result) => {
				persistAnalysis(result);
				log("Analysis complete");
			})
			.catch((err) => {
				log(`ERROR: analysis failed: ${err.message}`);
			});
	});

	// On-demand /analyze-session command
	pi.registerCommand("analyze-session", {
		description: "Run a critical post-mortem analysis of the current session",
		handler: async (args, ctx) => {
			ctx.ui.notify("Running session analysis...", "info");

			const entries = ctx.sessionManager.getEntries();
			const transcript = condenseTranscript(entries);

			if (!transcript.trim()) {
				ctx.ui.notify("Nothing to analyze — session is empty", "warning");
				return;
			}

			try {
				const result = await runAnalysis(ctx.cwd, transcript);
				persistAnalysis(result);
				lastAnalysisTime = Date.now();

				// Inject the analysis as a message so the user sees it
				pi.sendMessage({
					customType: "claude-watchdog-analysis",
					content: result,
					display: true,
				});
			} catch (err: any) {
				ctx.ui.notify(`Analysis failed: ${err.message}`, "error");
			}
		},
	});
}
