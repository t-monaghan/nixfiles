export interface WtWorktree {
	branch: string;
	path: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseWorktrees(output: string): WtWorktree[] {
	const parsed: unknown = JSON.parse(output);
	const legacy = Array.isArray(parsed);
	const items = legacy ? parsed : isRecord(parsed) ? parsed.items : undefined;
	if (!Array.isArray(items)) {
		throw new Error("Unsupported wt list JSON format: expected an array or an object with items");
	}

	return items.flatMap((item: unknown) => {
		if (!isRecord(item) || typeof item.branch !== "string") return [];
		const path = legacy ? item.path : isRecord(item.worktree) ? item.worktree.path : undefined;
		return typeof path === "string" && path.length > 0 ? [{ branch: item.branch, path }] : [];
	});
}
