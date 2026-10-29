import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, utimesSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const helper = resolve(import.meta.dirname, "pi-hud.mjs");
function exec(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}

test("lists saved sessions and resumes worktree sessions in the base tmux session", () => {
  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "pi-hud-test-"));
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
    writeFileSync(tmux, `#!/bin/sh\nprintf '%s\\n' "$*" >> "$PI_HUD_TEST_LOG"\nif [ "$1" = -S ]; then shift 2; fi\ncase "$1" in\n  display-message) if [ "$3" = -t ]; then printf '@9\\t$2\\n'; else printf '/dev/ttys000\\n'; fi;;\n  list-sessions) printf '$1\\thud\\t%s\\n' "$HOME/dev"; if [ -z "$PI_HUD_TEST_NO_REPO" ]; then printf '$2\\trepo\\t%s\\n' "$HOME/dev/repo"; fi;;\n  new-session) printf '$5\\n';;\n  new-window) printf '@5\\n';;\nesac\n`, { mode: 0o755 });
    const env = { ...process.env, HOME: home, XDG_CACHE_HOME: join(dir, "cache"), XDG_STATE_HOME: join(dir, "state"), PATH: `${bin}:${process.env.PATH}`, PI_HUD_TEST_LOG: log };
    const rows = JSON.parse(exec(process.execPath, [helper, "list"], { env }));
    assert.equal(rows.length, 1);
    assert.deepEqual([rows[0].key, rows[0].state, rows[0].repository, rows[0].session, rows[0].worktree], [file, "Saved", "repo", "Named task", "task"]);
    assert.equal(rows[0].updated, "now");
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    utimesSync(file, twoHoursAgo, twoHoursAgo);
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].updated, "2h ago");
    exec(process.execPath, [helper, "connect", file], { env });
    const calls = readFileSync(log, "utf8");
    assert.doesNotMatch(calls, /new-session/);
    assert.ok(calls.includes(`-t $2: -n pi-session- -c ${worktree} pi --session ${file} --session-dir ${sessions}`));
    assert.match(calls, /switch-client -c \/dev\/ttys000 -t \$2/);
    const registry = join(dir, "state", "pi-hud", "active");
    mkdirSync(registry, { recursive: true });
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, file, cwd: worktree, working: true, heartbeat: Date.now(), tmux: { socket: join(dir, "socket"), paneId: "%9", windowId: "@9" } }));
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].state, "Working");
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, file, cwd: worktree, working: true, waiting: true, heartbeat: Date.now() }));
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].state, "Waiting");
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, cwd: worktree, working: false, waiting: true, heartbeat: Date.now() }));
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env })).find(row => row.key === `live:${process.pid}`)?.state, "Waiting");
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, file, cwd: worktree, working: true, heartbeat: Date.now(), tmux: { socket: join(dir, "socket"), paneId: "%9", windowId: "@9" } }));
    writeFileSync(log, "");
    exec(process.execPath, [helper, "connect", file], { env });
    assert.ok(readFileSync(log, "utf8").includes(`-S ${join(dir, "socket")} switch-client -c /dev/ttys000 -t $2`));
    assert.doesNotMatch(readFileSync(log, "utf8"), /new-window/);
    rmSync(join(registry, `${process.pid}.json`));
    writeFileSync(log, "");
    exec(process.execPath, [helper, "connect", file], { env: { ...env, PI_HUD_TEST_NO_REPO: "1" } });
    const created = readFileSync(log, "utf8");
    assert.match(created, /new-session .* -s repo -c .*\/repo/);
    assert.match(created, /new-window .* -t \$5: .* -c .*\/repo\/\.worktrees\/task/);
    assert.match(created, /switch-client -c \/dev\/ttys000 -t \$5/);
    const old = join(sessions, "2020-01-01T00-00-00-000Z_old.jsonl");
    writeFileSync(old, JSON.stringify({ type: "session", cwd: worktree }));
    assert.ok(JSON.parse(exec(process.execPath, [helper, "list"], { env })).some(row => row.key === old));
    const eightDaysAgo = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000);
    utimesSync(old, eightDaysAgo, eightDaysAgo);
    assert.deepEqual(JSON.parse(exec(process.execPath, [helper, "list"], { env })).map(row => row.key), [file]);
    writeFileSync(join(registry, `${process.pid}.json`), JSON.stringify({ pid: process.pid, file: old, cwd: worktree, working: false, heartbeat: Date.now(), tmux: { socket: join(dir, "socket"), paneId: "%9", windowId: "@9" } }));
    const activeOld = JSON.parse(exec(process.execPath, [helper, "list"], { env }));
    assert.equal(activeOld.find(row => row.key === old)?.state, "Idle");
    rmSync(join(registry, `${process.pid}.json`));
    exec("git", ["-C", repo, "worktree", "remove", "--force", worktree]);
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env }))[0].state, "Missing directory");
    const jobs = join(home, "dev", "agents", "sessions", "dispatcher");
    mkdirSync(jobs, { recursive: true });
    writeFileSync(join(jobs, "jobs.json"), JSON.stringify([{
      id: "job-1", repo: "repo", branch: "task", worktreePath: repo,
      sessionDir: join(jobs, "job-1", "session"), state: "running", createdAt: new Date(Date.now() - 3 * 60 * 1000).toISOString(),
    }]));
    const background = JSON.parse(exec(process.execPath, [helper, "list"], { env }));
    assert.equal(background[0].key, "job:job-1");
    assert.equal(background[0].state, "Background");
    assert.equal(background[0].updated, "3m ago");
    writeFileSync(join(jobs, "jobs.json"), JSON.stringify([{
      id: "job-1", repo: "repo", branch: "task", worktreePath: repo,
      sessionDir: join(jobs, "job-1", "session"), state: "completed", completedAt: eightDaysAgo.toISOString(),
    }]));
    assert.ok(!JSON.parse(exec(process.execPath, [helper, "list"], { env })).some(row => row.key === "job:job-1"));
    writeFileSync(join(jobs, "jobs.json"), JSON.stringify([{
      id: "job-1", repo: "repo", branch: "task", worktreePath: repo,
      sessionDir: join(jobs, "job-1", "session"), state: "completed",
      completedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    }]));
    assert.equal(JSON.parse(exec(process.execPath, [helper, "list"], { env })).find(row => row.key === "job:job-1")?.updated, "3d ago");
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
