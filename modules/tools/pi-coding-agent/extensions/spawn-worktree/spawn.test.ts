import assert from "node:assert/strict";
import childProcess from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { syncBuiltinESMExports } from "node:module";
import { join } from "node:path";
import { afterEach, beforeEach, test, mock } from "node:test";
import { prepareWorktree, scheduleReplacement } from "./spawn.ts";

const run = childProcess.spawnSync;
const cwd = "/repo";
const path = "/repo/.worktrees/feature";
const opts = { branch: "feature/rex-worktree", task: "Implement 'foo'; $(do not execute)\nThen test it." };
const worktrees = [{ branch: opts.branch, path }];
let savedSession: string | undefined;
let savedBlock: string | undefined;

beforeEach(() => {
	savedSession = process.env.REX_SESSION;
	savedBlock = process.env.REX_BLOCK;
	process.env.REX_SESSION = "session:current";
	process.env.REX_BLOCK = "block:current";
});
afterEach(() => {
	mock.restoreAll();
	syncBuiltinESMExports();
	if (savedSession === undefined) delete process.env.REX_SESSION;
	else process.env.REX_SESSION = savedSession;
	if (savedBlock === undefined) delete process.env.REX_BLOCK;
	else process.env.REX_BLOCK = savedBlock;
});

function commands(overrides: { worktrees?: unknown[]; fail?: string; missing?: string } = {}) {
	const calls: { command: string; args: string[] }[] = [];
	let lists = 0;
	mock.method(childProcess, "spawnSync", (command: string, args: string[]) => {
		calls.push({ command, args });
		const ok = (value: unknown) => ({ status: 0, stdout: JSON.stringify(value), stderr: "" });
		if (command === "bash") return { status: args[1] === `command -v ${overrides.missing}` ? 1 : 0 };
		assert.notEqual(command, "tmux");
		const operation = args[2];
		if (operation === overrides.fail) return { status: 1, stdout: "", stderr: "test failure" };
		if (command === "rex" && ["inspect", "rename"].includes(operation)) return ok({});
		if (command === "wt" && operation === "list") return ok(overrides.worktrees?.[lists++] ?? worktrees);
		if (command === "wt" && operation === "switch") return ok({});
		throw new Error(`Unexpected command: ${command} ${args.join(" ")}`);
	});
	syncBuiltinESMExports();
	return calls;
}

test("reuses the worktree and renames only the current pane with a short branch name", () => {
	const calls = commands();
	const result = prepareWorktree(opts, { cwd });
	assert.equal(result.sessionId, "session:current");
	assert.equal(result.blockId, "block:current");
	assert.equal(result.paneName, "rex-worktree");
	assert.equal(result.worktreePath, path);
	assert.equal(result.created, false);
	assert.deepEqual(calls.filter((call) => call.command === "rex").map((call) => call.args), [
		["--autostart=false", "block", "inspect", "-s", "session:current", "block:current", "--json"],
		["--autostart=false", "block", "rename", "-s", "session:current", "block:current", "rex-worktree"],
	]);
	assert.equal(result.piArgs.length, 1);
	assert.ok(result.piArgs[0].endsWith(opts.task));
	assert.ok(result.piArgs[0].includes("Do not merge it."));
	assert.equal(calls.some((call) => call.args.includes("switch")), false);
});

test("creates a missing worktree with the requested base, model, and pane name", () => {
	const calls = commands({ worktrees: [[], worktrees] });
	const result = prepareWorktree({ ...opts, baseBranch: "main", model: "requested-model", paneName: "rex handoff" }, { cwd });
	assert.equal(result.created, true);
	assert.equal(result.paneName, "rex handoff");
	assert.deepEqual(calls.find((call) => call.args.includes("switch"))?.args,
		["-C", cwd, "switch", "-c", opts.branch, "-b", "main", "-x", "true"]);
	assert.deepEqual(result.piArgs.slice(0, 2), ["--model", "requested-model"]);
});

test("keeps old name parameters as pane name aliases", () => {
	commands();
	assert.equal(prepareWorktree({ ...opts, windowName: "old-name" }, { cwd }).paneName, "old-name");
	assert.equal(prepareWorktree({ ...opts, sessionName: "session-alias" }, { cwd }).paneName, "session-alias");
	assert.equal(prepareWorktree({ ...opts, windowName: "old-name", sessionName: "session-alias", paneName: "new-name" }, { cwd }).paneName, "new-name");
});

test("requires Rex context and installed commands before changing worktrees", () => {
	const calls = commands({ missing: "rex" });
	assert.throws(() => prepareWorktree(opts, { cwd }), /rex.*not found/);
	assert.equal(calls.some((call) => call.command === "wt"), false);
	mock.restoreAll();
	commands();
	delete process.env.REX_BLOCK;
	assert.throws(() => prepareWorktree(opts, { cwd }), /inside a Rex pane/);
});

test("rejects invalid input and limits the default pane name to 40 characters", () => {
	const calls = commands();
	assert.throws(() => prepareWorktree({ ...opts, branch: "-bad" }, { cwd }), /Invalid branch/);
	assert.throws(() => prepareWorktree({ ...opts, task: " " }, { cwd }), /Task is required/);
	for (const paneName of ["bad\nname", " ", "x".repeat(41)]) {
		assert.throws(() => prepareWorktree({ ...opts, paneName }, { cwd }), /Rex pane name/);
	}
	assert.equal(calls.some((call) => call.command === "rex"), false);
	mock.restoreAll();
	const branch = "x".repeat(60);
	commands({ worktrees: [[{ branch, path }]] });
	assert.equal(prepareWorktree({ ...opts, branch }, { cwd }).paneName.length, 40);
});

test("reports pane inspection, worktree creation, and pane rename failures", () => {
	for (const fail of ["inspect", "switch", "rename"]) {
		const calls = commands({ worktrees: [[], worktrees], fail });
		assert.throws(() => prepareWorktree(opts, { cwd }), /test failure/);
		if (fail === "inspect") assert.equal(calls.some((call) => call.command === "wt"), false);
		if (fail === "switch") assert.equal(calls.some((call) => call.args.includes("rename")), false);
		mock.restoreAll();
	}
});

test("removes the exit handler if shutdown fails", () => {
	commands();
	const replacement = prepareWorktree(opts, { cwd });
	const listeners = process.listenerCount("exit");
	assert.throws(() => scheduleReplacement(replacement, () => { throw new Error("shutdown failed"); }), /shutdown failed/);
	assert.equal(process.listenerCount("exit"), listeners);
});

test("replaces the process after clean shutdown, retaining PID, cwd, and literal arguments", () => {
	assert.ok(process.env.PI_SESSION_TEMP, "PI_SESSION_TEMP is required");
	const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "worktree-replacement-"));
	try {
		writeFileSync(join(dir, "pi"), '#!/bin/bash\nprintf "%s\\n" "$$" "$PWD" "$@"\n', { mode: 0o755 });
		const replacement = {
			sessionId: "session:test", blockId: "block:test", paneName: "test", worktreePath: dir,
			created: false, piArgs: ["--model", "requested-model", opts.task],
		};
		const script = `
			import { scheduleReplacement } from ${JSON.stringify(new URL("./spawn.ts", import.meta.url).href)};
			console.log(process.pid);
			scheduleReplacement(${JSON.stringify(replacement)}, () => process.exit(Number(process.env.TEST_EXIT)));
		`;
		const env = { ...process.env, PATH: `${dir}:${process.env.PATH}`, TEST_EXIT: "0" };
		const result = run(process.execPath, ["--input-type=module", "-e", script], { env, encoding: "utf8", timeout: 10000 });
		assert.equal(result.status, 0, result.stderr);
		const [oldPid, newPid, ...output] = result.stdout.trimEnd().split("\n");
		assert.equal(newPid, oldPid);
		assert.deepEqual(output, [dir, ...replacement.piArgs].join("\n").split("\n"));
		const failed = run(process.execPath, ["--input-type=module", "-e", script], {
			env: { ...env, TEST_EXIT: "1" }, encoding: "utf8", timeout: 10000,
		});
		assert.equal(failed.status, 1);
		assert.match(failed.stdout, /^\d+\n$/);
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
});
