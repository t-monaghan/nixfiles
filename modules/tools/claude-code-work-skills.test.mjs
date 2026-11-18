import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, readlinkSync, rmSync, symlinkSync } from "node:fs";
import path from "node:path";
import test from "node:test";

const script = new URL("./claude-code-work-skills.sh", import.meta.url).pathname;

test("installs work skills, updates repositories, and preserves existing skills", () => {
  const root = mkdtempSync(path.join(process.env.PI_SESSION_TEMP ?? process.env.TMPDIR, "claude-work-skills-"));
  try {
    const bin = path.join(root, "bin");
    const repos = path.join(root, "repos");
    const skills = path.join(root, "skills");
    const log = path.join(root, "git.log");
    mkdirSync(bin);
    writeFileSync(path.join(bin, "git"), `#!/usr/bin/env bash
set -eu
printf '%s\\n' "$*" >> "$GIT_LOG"
if [[ "$1" == clone ]]; then
  checkout="\${!#}"
  repo=\${checkout##*/}
  source_dir=skills
  [[ "$repo" != sre-health-triage ]] || source_dir=.claude/skills
  mkdir -p "$checkout/.git" "$checkout/$source_dir/$repo" "$checkout/$source_dir/not-a-skill"
  printf 'skill' > "$checkout/$source_dir/$repo/SKILL.md"
  printf 'resource' > "$checkout/$source_dir/$repo/reference.md"
fi
`, { mode: 0o755 });
    const run = () => spawnSync("bash", [script, repos, skills], {
      env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, GIT_LOG: log },
      encoding: "utf8",
    });
    let result = run();
    assert.equal(result.status, 0, result.stderr);
    for (const repo of ["sre-health-triage", "sre-ai-toolkit", "ca-agent-context"]) {
      const sourceDir = repo === "sre-health-triage" ? ".claude/skills" : "skills";
      assert.equal(readlinkSync(path.join(skills, repo)), path.join(repos, repo, sourceDir, repo));
      assert.equal(readFileSync(path.join(skills, repo, "reference.md"), "utf8"), "resource");
    }
    result = run();
    assert.equal(result.status, 0, result.stderr);
    const calls = readFileSync(log, "utf8");
    assert.equal(calls.match(/clone --depth 1 --branch main/g).length, 3);
    assert.equal(calls.match(/pull --ff-only origin main/g).length, 3);
    rmSync(path.join(skills, "ca-agent-context"));
    writeFileSync(path.join(skills, "ca-agent-context"), "user skill");
    result = run();
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Refusing to replace existing skill/);
    assert.equal(readFileSync(path.join(skills, "ca-agent-context"), "utf8"), "user skill");
    rmSync(path.join(skills, "ca-agent-context"));
    symlinkSync(path.join(root, "missing"), path.join(skills, "ca-agent-context"));
    result = run();
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Refusing to replace existing skill/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
