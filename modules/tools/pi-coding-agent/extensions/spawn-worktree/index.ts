import { prepareWorktree, scheduleReplacement } from "./spawn.ts";
import { Type } from "@mariozechner/pi-ai";
import {
	defineTool,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const SpawnParams = Type.Object({
	branch: Type.String({ description: "Git branch for the worktree. Created if missing." }),
	task: Type.String({ description: "Task for a fresh pi session in the current Rex pane." }),
	baseBranch: Type.Optional(
		Type.String({ description: "Base branch for `wt switch -c -b <base>`. Defaults to repo default branch." }),
	),
	model: Type.Optional(
		Type.String({ description: "Model override. Set only when the user explicitly requests a specific model." }),
	),
	paneName: Type.Optional(
		Type.String({ description: "Short name relevant to the change, at most 40 characters. Defaults to the last branch component." }),
	),
	sessionName: Type.Optional(Type.String({ description: "Deprecated alias for paneName. Does not rename the Rex session." })),
	windowName: Type.Optional(Type.String({ description: "Deprecated alias for paneName. Does not rename the Rex window." })),
});

function requireInteractivePane(ctx: ExtensionContext): void {
	if (ctx.mode !== "tui" || !process.stdin.isTTY || !process.stdout.isTTY) {
		throw new Error("Use spawn_worktree from interactive pi in a Rex pane");
	}
}

const spawnWorktreeTool = defineTool({
	name: "spawn_worktree",
	label: "Open worktree in current pane",
	description: [
		"Create or reuse a git worktree and replace the current pi session with a fresh pi session in the same Rex pane.",
		"This ends the current pi session; it does not start a parallel agent or create a Rex session, window, or split.",
		"Use only when the user wants to switch the current pane to the worktree. Choose a short paneName relevant to the change.",
		"Requires interactive pi inside Rex. Omit model unless the user explicitly requests a specific model.",
	].join(" "),
	promptSnippet: "spawn_worktree: open a worktree in the current Rex pane, rename the pane, and replace the current pi session.",
	parameters: SpawnParams,
	async execute(_id, params, _signal, _onUpdate, ctx) {
		try {
			requireInteractivePane(ctx);
			const replacement = prepareWorktree(params, ctx);
			scheduleReplacement(replacement, () => ctx.shutdown());
			return {
				content: [{ type: "text", text: `Opening ${replacement.worktreePath} in the current Rex pane '${replacement.paneName}'. The current pi session will end.` }],
				details: { worktreePath: replacement.worktreePath, paneName: replacement.paneName, blockId: replacement.blockId, created: replacement.created },
				terminate: true,
			};
		} catch (err) {
			const message = err instanceof Error ? err.message : String(err);
			return {
				content: [{ type: "text", text: `spawn_worktree failed: ${message}` }],
				details: { error: message },
				isError: true,
			};
		}
	},
});

export default function (pi: ExtensionAPI) {
	pi.registerTool(spawnWorktreeTool);
	pi.registerCommand("spawn", {
		description: "Open a worktree in the current Rex pane with a fresh pi session (usage: /spawn <branch> <task>)",
		handler: async (args: string, ctx: ExtensionCommandContext) => {
			const match = args.trim().match(/^(\S+)\s+([\s\S]+)$/);
			if (!match) {
				ctx.ui.notify("Usage: /spawn <branch> <task>", "warning");
				return;
			}
			try {
				requireInteractivePane(ctx);
				await ctx.waitForIdle();
				const replacement = prepareWorktree({ branch: match[1], task: match[2] }, ctx);
				ctx.ui.notify(`Opening ${replacement.worktreePath} in this pane as '${replacement.paneName}'`, "info");
				scheduleReplacement(replacement, () => ctx.shutdown());
			} catch (err) {
				ctx.ui.notify(`/spawn failed: ${err instanceof Error ? err.message : String(err)}`, "error");
			}
		},
	});
}
