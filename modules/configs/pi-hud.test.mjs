import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const helper = resolve(import.meta.dirname, "pi-hud.mjs");
function exec(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}

test("lists saved sessions and resumes worktree sessions in the base tmux session", () => {
  const dir = mkdtempSync(join(tmpdir(), "pi-hud-test-"));
  try {
    const home = join(dir, "home"), repo = join(home, "dev", "repo"), worktree = join(repo, ".worktrees", "task");
    const sessions = join(home, ".pi", "agent", "sessions", "project");
    const bin = join(dir, "bin"), log = join(dir, "tmux.log");
    mkdirSync(repo, { recursive: true });
    mkdirSync(sessions, { recursive: true });
    mkdirSync(bin);
    exec("git", ["init", "-q", repo]);
    exec("git", ["-C", repo, "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "--allow-empty", "-qm", "init"]);
    exec("git", ["-C", repo, "worktree", "add", "-qb", "task", worktree]);
    const file = join(sessions, "session.jsonl");
    writeFileSync(file, [
      JSON.stringify({ type: "session", id: "session-123", cwd: worktree }),
      JSON.stringify({ type: "message", message: { role: "user", content: "Test task" } }),
      JSON.stringify({ type: "session_info", name: "Named task" }),
    ].join("\n"));
    const tmux = join(bin, "tmux");
    writeFileSync(tmux, `#!/bin/sh\nprintf '%s\\n' "$*" >> "$PI_HUD_TEST_LOG"\ncase "$1" in\n  list-sessions) exit 0;;\n  new-session) printf '$5\\n';;\n  new-window) printf '@5\\n';;\nesac\n`, { mode: 0o755 });
    const env = { ...process.env, HOME: home, XDG_CACHE_HOME: join(dir, "cache"), XDG_STATE_HOME: join(dir, "state"), PATH: `${bin}:${process.env.PATH}`, PI_HUD_TEST_LOG: log };
    const rows = JSON.parse(exec(process.execPath, [helper, "list"], { env }));
    assert.equal(rows.length, 1);
    assert.deepEqual([rows[0].key, rows[0].state, rows[0].repository, rows[0].session, rows[0].worktree], [file, "Saved", "repo", "Named task", "task"]);
    exec(process.execPath, [helper, "connect", file], { env });
    const calls = readFileSync(log, "utf8");
    assert.match(calls, /new-session .* -c .*\/repo/);
    assert.ok(calls.includes(`-c ${worktree} pi --session ${file} --session-dir ${sessions}`));
    assert.match(calls, /switch-client -t \$5/);
    const registry = join(dir, "state", "pi-hud", "active");
    mkdirSync(registry, { recursive: true });
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, file, cwd: worktree, working: true, heartbeat: Date.now() }));
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].state, "Working");
    rmSync(join(registry, `${process.pid}.json`));
    exec("git", ["-C", repo, "worktree", "remove", "--force", worktree]);
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].state, "Missing directory");
    const jobs = join(home, "dev", "agents", "sessions", "dispatcher");
    mkdirSync(jobs, { recursive: true });
    writeFileSync(join(jobs, "jobs.json"), JSON.stringify([{
      id: "job-1", repo: "repo", branch: "task", worktreePath: repo,
      sessionDir: join(jobs, "job-1", "session"), state: "running", createdAt: new Date().toISOString(),
    }]));
    const background = JSON.parse(exec(process.execPath, [helper, "list"], { env }));
    assert.equal(background[0].key, "job:job-1");
    assert.equal(background[0].state, "Background");
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
