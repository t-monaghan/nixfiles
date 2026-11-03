import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";

const tmux = readFileSync(new URL("tmux.nix", import.meta.url), "utf8");
const fish = readFileSync(new URL("fish.nix", import.meta.url), "utf8");
const pickerFilter = tmux.match(/def age:[\s\S]*?(?=\n\s*'\n)/)?.[0];
const cleanupFilter = fish.match(/jq -r '(\.items\[\][^']+)'/)?.[1];

function query(filter, input) {
  assert.ok(filter, "jq filter exists in configuration");
  const result = spawnSync("jq", ["-r", filter], {
    input: JSON.stringify(input), encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trimEnd().split("\n").filter(Boolean);
}

function item(branch, worktree = {}, extra = {}) {
  return {
    branch,
    head: {
      committed_at: new Date(Date.now() - 7200_000).toISOString().replace(/\.\d{3}Z$/, "Z"),
      subject: "Worktree commit",
    },
    worktree: { path: `/repo/${branch}`, main: false, current: false, ...worktree },
    display: { symbols: "!" },
    ...extra,
  };
}

function envelope(items) {
  return { schema: 2, repo: { default_branch: "main" }, collected: { ci: false }, items };
}

const entries = [
  item("main", { main: true }),
  item("feature"),
  item("current", { current: true }),
  item(null, { detached: true }),
  item("branch-only", {}, { worktree: null }),
];

test("picker reads schema 2 and lists linked worktrees, including the current worktree", () => {
  assert.deepEqual(query(pickerFilter, envelope(entries)), [
    "wt\tfeature\t\u2442 feature\t!\t2h\tWorktree commit",
    "wt\tcurrent\t\u2442 current\t!\t2h\tWorktree commit",
  ]);
});

test("picker preserves fork branch keys, strips ref suffixes, and truncates subjects", () => {
  const branch = "feature:refs/pull/42/head";
  const entry = item(branch, {}, { display: {}, head: { ...item(branch).head, subject: "x".repeat(80) } });
  assert.deepEqual(query(pickerFilter, envelope([entry])), [
    `wt\t${branch}\t\u2442 feature\t\t2h\t${"x".repeat(60)}`,
  ]);
});

test("wtclean excludes main, current, detached, and branch-only entries", () => {
  assert.deepEqual(query(cleanupFilter, envelope(entries)), ["feature\t/repo/feature"]);
});

test("empty worktree lists produce no rows", () => {
  assert.deepEqual(query(pickerFilter, envelope([])), []);
  assert.deepEqual(query(cleanupFilter, envelope([])), []);
});
