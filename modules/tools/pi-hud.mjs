import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, openSync, readFileSync, readdirSync, realpathSync, renameSync, statSync, writeFileSync, closeSync, unlinkSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";

const home = homedir();
const stateDir = join(process.env.XDG_STATE_HOME || join(home, ".local/state"), "pi-hud");
const cacheDir = join(process.env.XDG_CACHE_HOME || join(home, ".cache"), "pi-hud");
const registryDir = join(stateDir, "active");
const sessionRoot = join(home, ".pi/agent/sessions");
const agentRoot = (() => {
  try { return JSON.parse(readFileSync(join(home, ".pi/agent/dispatch.json"), "utf8")).agentRoot; }
  catch { return join(home, "dev/agents"); }
})();
const jobsRoot = join(agentRoot, "sessions");
const recentSince = Date.now() - 7 * 24 * 60 * 60 * 1000;

function entries(path) {
  try { return readdirSync(path, { withFileTypes: true }); } catch { return []; }
}
function json(path) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return null; }
}
function run(command, args, options = {}) {
  const r = spawnSync(command, args, { encoding: "utf8", ...options });
  if (r.status !== 0) throw Error(`${command}: ${(r.stderr || r.stdout || r.error?.message || "failed").trim()}`);
  return r.stdout.trim();
}
function files() {
  const roots = entries(sessionRoot).filter(e => e.isDirectory()).map(e => join(sessionRoot, e.name));
  for (const dir of (process.env.PI_HUD_SESSION_DIRS || "").split(":").filter(Boolean)) {
    roots.push(dir, ...entries(dir).filter(e => e.isDirectory()).map(e => join(dir, e.name)));
  }
  for (const dispatcher of entries(jobsRoot).filter(e => e.isDirectory())) {
    for (const job of entries(join(jobsRoot, dispatcher.name)).filter(e => e.isDirectory())) {
      roots.push(join(jobsRoot, dispatcher.name, job.name, "session"));
    }
  }
  return roots.flatMap(dir => entries(dir).filter(e => e.isFile() && e.name.endsWith(".jsonl")).map(e => join(dir, e.name)));
}
function jobs() {
  const result = new Map();
  for (const dir of entries(jobsRoot).filter(e => e.isDirectory())) {
    const path = join(jobsRoot, dir.name, "jobs.json");
    for (const job of json(path) || []) {
      if (job?.id && job?.sessionDir) result.set(job.sessionDir, { ...job, registryPath: path });
    }
  }
  return result;
}
function firstText(message) {
  const content = message?.content;
  return (typeof content === "string" ? content : Array.isArray(content) ? content.find(c => c.type === "text")?.text : "") || "";
}
function clean(text) { return String(text || "").replace(/\s+/g, " ").slice(0, 90); }
function timeSince(timestamp, now) {
  const elapsed = Math.max(0, Math.floor((now - timestamp) / 1000));
  if (!Number.isFinite(elapsed)) return "—";
  if (elapsed < 60) return "now";
  if (elapsed < 3600) return `${Math.floor(elapsed / 60)}m ago`;
  if (elapsed < 86400) return `${Math.floor(elapsed / 3600)}h ago`;
  return `${Math.floor(elapsed / 86400)}d ago`;
}
function metadata(file) {
  const lines = readFileSync(file, "utf8").split("\n");
  let header, name, first;
  for (const line of lines) {
    if (!line) continue;
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    if (entry.type === "session" && !header) header = entry;
    if (entry.type === "session_info") name = entry.name;
    if (entry.type === "message" && entry.message?.role === "user" && !first) first = clean(firstText(entry.message));
  }
  return { cwd: header?.cwd, id: header?.id, name: clean(name || first || header?.id || basename(file)) };
}
function index() {
  mkdirSync(cacheDir, { recursive: true, mode: 0o700 });
  const path = join(cacheDir, "sessions.json");
  const old = json(path) || {};
  const next = {};
  for (const file of files()) {
    try {
      const s = statSync(file);
      const cached = old[file];
      if (s.mtimeMs < recentSince) continue;
      next[file] = cached?.mtimeMs === s.mtimeMs && cached?.size === s.size
        ? cached : { ...metadata(file), mtimeMs: s.mtimeMs, size: s.size };
    } catch { /* A session can disappear during refresh. */ }
  }
  const temp = `${path}.${process.pid}`;
  writeFileSync(temp, JSON.stringify(next), { mode: 0o600 });
  renameSync(temp, path);
  return next;
}
function active() {
  const result = new Map();
  for (const e of entries(registryDir).filter(e => e.isFile() && e.name.endsWith(".json"))) {
    const record = json(join(registryDir, e.name));
    if (!record || Date.now() - record.heartbeat > 45000) continue;
    try { process.kill(record.pid, 0); } catch { continue; }
    if (record.file) result.set(record.file, record);
    else result.set(`live:${record.pid}`, record);
  }
  return result;
}
function gitBase(cwd) {
  if (!cwd || !existsSync(cwd)) return null;
  try {
    const output = run("git", ["-C", cwd, "worktree", "list", "--porcelain"]);
    const main = output.split("\n").find(line => line.startsWith("worktree "));
    if (main) return main.slice(9);
  } catch { /* Non-git directories use their own tmux session. */ }
  return cwd;
}
function liveState(record) { return record.waiting ? "Waiting" : record.working ? "Working" : "Idle"; }
function summaryRows() {
  const saved = index(), live = active(), jobMap = jobs(), rows = [], indexedJobs = new Set(), now = Date.now();
  for (const [file, info] of Object.entries(saved)) {
    const running = live.get(file), job = jobMap.get(dirname(file));
    if (job) indexedJobs.add(job.id);
    const cwd = info.cwd || running?.cwd || job?.worktreePath;
    const base = gitBase(cwd);
    const state = running?.waiting ? "Waiting" : job?.state === "running" ? "Background" : running ? liveState(running) : !base ? "Missing directory" : "Saved";
    rows.push({ key: file, state, repository: job?.repo || (base ? basename(base) : "—"), session: info.name, worktree: cwd && base && resolve(cwd) !== resolve(base) ? basename(cwd) : "main", updated: timeSince(info.mtimeMs, now), sort: running ? 2 : 0, time: info.mtimeMs });
  }
  for (const [key, record] of live) {
    if (saved[key]) continue;
    const base = gitBase(record.cwd);
    rows.push({ key, state: liveState(record), repository: base ? basename(base) : "—", session: clean(record.name || record.id || "Ephemeral pi"), worktree: base && record.cwd !== base ? basename(record.cwd) : "main", updated: timeSince(record.heartbeat, now), sort: 2, time: record.heartbeat });
  }
  for (const job of jobMap.values()) {
    if (indexedJobs.has(job.id) || (job.state !== "running" && (Date.parse(job.completedAt || job.createdAt) || 0) < recentSince)) continue;
    const time = Date.parse(job.completedAt || job.createdAt);
    rows.push({ key: `job:${job.id}`, state: job.state === "running" ? "Background" : job.state, repository: job.repo, session: `${job.repo}:${job.branch}`, worktree: basename(job.worktreePath), updated: timeSince(time, now), sort: job.state === "running" ? 1 : 0, time: time || 0 });
  }
  rows.sort((a, b) => b.sort - a.sort || b.time - a.time);
  return rows.map(({ sort, time, ...row }) => row);
}
function tmux(args, socket) { return run("tmux", [...(socket ? ["-S", socket] : []), ...args]); }
function showPane(record) {
  if (!record?.tmux) return false;
  const { socket, paneId, windowId } = record.tmux;
  try {
    const [currentWindow, currentSession] = tmux(["display-message", "-p", "-t", paneId, "#{window_id}\t#{session_id}"], socket).split("\t");
    if (currentWindow !== windowId || !currentSession?.startsWith("$")) return false;
    const client = tmux(["display-message", "-p", "#{client_name}"]);
    if (!client) return false;
    tmux(["select-window", "-t", windowId], socket);
    tmux(["select-pane", "-t", paneId], socket);
    tmux(["switch-client", "-c", client, "-t", currentSession], socket);
    return true;
  } catch { return false; }
}
function baseSession(base) {
  const sessions = tmux(["list-sessions", "-F", "#{session_id}\t#{session_name}\t#{session_path}"]).split("\n").map(line => line.split("\t"));
  const existing = sessions.find(parts => {
    try { return parts[2] && realpathSync(parts[2]) === realpathSync(base); }
    catch { return false; }
  });
  if (existing) return existing[0];
  const name = basename(base).replace(/[^\w-]/g, "-");
  const sessionName = sessions.some(parts => parts[1] === name) ? `${name}-${process.pid}` : name;
  return tmux(["new-session", "-d", "-P", "-F", "#{session_id}", "-s", sessionName, "-c", base]);
}
function openWindow(base, cwd, command, args, name) {
  const client = tmux(["display-message", "-p", "#{client_name}"]);
  if (!client) throw Error("No tmux client is attached to HUD.");
  const sessionId = baseSession(base);
  const windowId = tmux(["new-window", "-d", "-P", "-F", "#{window_id}", "-t", `${sessionId}:`, "-n", name, "-c", cwd, command, ...args]);
  tmux(["select-window", "-t", windowId]);
  tmux(["switch-client", "-c", client, "-t", sessionId]);
}
async function connect(key) {
  const live = active();
  if (showPane(live.get(key))) return;
  if (key.startsWith("live:")) throw Error("This pi process has no attachable tmux pane.");
  const jobMap = jobs();
  const job = [...jobMap.values()].find(j => key === `job:${j.id}` || key.startsWith(`${j.sessionDir}/`));
  if (job?.state === "running") {
    const base = gitBase(job.worktreePath);
    if (!base) throw Error("The dispatcher worktree is missing.");
    openWindow(base, job.worktreePath, process.execPath, [process.argv[1], "watch", job.id], `pi-${job.id}`);
    return;
  }
  if (key.startsWith("job:")) throw Error("This job has no saved pi session.");
  const saved = index()[key];
  if (!saved || !key.endsWith(".jsonl")) throw Error("The pi session is missing.");
  const cwd = saved.cwd;
  const base = gitBase(cwd);
  if (!base) throw Error(`The original pi working directory is missing: ${cwd || "unknown"}`);
  mkdirSync(stateDir, { recursive: true, mode: 0o700 });
  const lock = join(stateDir, `launch-${saved.id || basename(key)}.lock`);
  let fd;
  try { fd = openSync(lock, "wx", 0o600); }
  catch {
    if (Date.now() - statSync(lock).mtimeMs > 30000) {
      unlinkSync(lock);
      fd = openSync(lock, "wx", 0o600);
    } else throw Error("This pi session is already opening. Try again shortly.");
  }
  try {
    if (showPane(active().get(key))) return;
    if (active().has(key)) throw Error("This pi session is active outside tmux. Do not open a second writer.");
    openWindow(base, cwd, process.env.PI_HUD_PI || "pi", ["--session", key, "--session-dir", dirname(key)], `pi-${(saved.id || basename(key)).slice(0, 8)}`);
    await new Promise(resolve => setTimeout(resolve, 2500));
  } finally {
    closeSync(fd);
    unlinkSync(lock);
  }
}
async function watch(id) {
  while (true) {
    const job = [...jobs().values()].find(j => j.id === id);
    process.stdout.write(`\x1b[2J\x1b[Hpi job: ${id}\nrepository: ${job?.repo || "unknown"}\nbranch: ${job?.branch || "unknown"}\nstate: ${job?.state || "unknown"}\n\n${job?.summary || "Waiting for the dispatcher result..."}\n\nClose this window to return.\n`);
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
}
try {
  if (process.argv[2] === "list") console.log(JSON.stringify(summaryRows()));
  else if (process.argv[2] === "connect" && process.argv[3]) await connect(process.argv[3]);
  else if (process.argv[2] === "watch" && process.argv[3]) await watch(process.argv[3]);
  else throw Error("Usage: pi-hud list | connect <key>");
} catch (error) {
  console.error(`pi-hud: ${error.message}`);
  process.exitCode = 1;
}
