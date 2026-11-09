import assert from "node:assert/strict";
import { test } from "node:test";
import { parseWorktrees } from "./output.ts";

test("reads legacy worktree arrays", () => {
	assert.deepEqual(parseWorktrees(JSON.stringify([
		{ branch: "main", path: "/repo", kind: "worktree", is_main: true },
		{ branch: "feature", path: "/repo/.worktrees/feature" },
	])), [
		{ branch: "main", path: "/repo" },
		{ branch: "feature", path: "/repo/.worktrees/feature" },
	]);
});

test("reads schema 2 items with nested worktree paths", () => {
	assert.deepEqual(parseWorktrees(JSON.stringify({
		schema: 2,
		repo: { default_branch: "main" },
		collected: { ci: false },
		items: [
			{ branch: "main", worktree: { path: "/repo", main: true } },
			{ branch: "feature", worktree: { path: "/repo/.worktrees/feature" } },
		],
	})), [
		{ branch: "main", path: "/repo" },
		{ branch: "feature", path: "/repo/.worktrees/feature" },
	]);
});

test("skips branches without worktrees and detached or malformed entries", () => {
	const invalid = [null, [], {}, { branch: "unused" },
		{ branch: null, path: "/detached", worktree: { path: "/detached" } },
		{ branch: "bad", path: 42, worktree: { path: 42 } },
		{ branch: "empty", path: "", worktree: { path: "" } }];
	assert.deepEqual(parseWorktrees(JSON.stringify(invalid)), []);
	assert.deepEqual(parseWorktrees(JSON.stringify({ schema: 2, items: invalid })), []);
});

test("accepts empty lists in both formats", () => {
	assert.deepEqual(parseWorktrees("[]"), []);
	assert.deepEqual(parseWorktrees('{"schema":2,"items":[]}'), []);
});

test("rejects malformed JSON and unsupported envelopes instead of reporting no worktrees", () => {
	assert.throws(() => parseWorktrees("not json"), SyntaxError);
	for (const value of [null, {}, { items: {} }, { worktrees: [] }]) {
		assert.throws(() => parseWorktrees(JSON.stringify(value)), /Unsupported wt list JSON format/);
	}
});
