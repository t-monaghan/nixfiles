import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

const policy = JSON.parse(readFileSync(new URL("../pi-coding-agent/sandbox.json", import.meta.url), "utf8"));

test("Linux sandbox permits commits and preserves configured write denies", {
  skip: process.platform !== "linux",
}, async () => {
  const { SandboxManager } = await import("@anthropic-ai/sandbox-runtime");
  const originalCwd = process.cwd();
  const root = mkdtempSync(join(tmpdir(), "pi-sandbox-git-"));
  const repo = join(root, "repo");
  const shell = spawnSync("bash", ["-c", "command -v bash"], { encoding: "utf8" }).stdout.trim();
  mkdirSync(repo);
  mkdirSync(join(repo, ".pi"));
  writeFileSync(join(repo, ".env"), "secret=test\n");
  writeFileSync(join(repo, ".pi", "sandbox.json"), "{}\n");
  process.chdir(repo);

  async function run(command) {
    const wrapped = await SandboxManager.wrapWithSandbox(command, shell);
    const result = spawnSync(shell, ["-c", wrapped], { encoding: "utf8" });
    SandboxManager.cleanupAfterCommand();
    assert.equal(result.status, 0, `${command}\n${result.stdout}\n${result.stderr}`);
    return result.stdout;
  }

  try {
    await SandboxManager.initialize({
      ...policy,
      filesystem: {
        ...policy.filesystem,
        allowWrite: [".", join(repo, ".git")],
      },
    });
    await run("git init && git -c user.name=test -c user.email=test@example.com commit --allow-empty -m initial");
    writeFileSync(join(repo, "tracked.txt"), "first\n");
    await run("git add tracked.txt && git -c user.name=test -c user.email=test@example.com commit -m first");
    writeFileSync(join(repo, "tracked.txt"), "second\n");
    await run("git add tracked.txt && git -c user.name=test -c user.email=test@example.com commit -m second");
    assert.equal((await run("git log -1 --format=%s")).trim(), "second");
    await run("if printf changed > .env; then exit 1; fi; if printf changed > .pi/sandbox.json; then exit 1; fi");
    assert.equal(readFileSync(join(repo, ".env"), "utf8"), "secret=test\n");
    assert.equal(readFileSync(join(repo, ".pi", "sandbox.json"), "utf8"), "{}\n");

    await run("git worktree add .worktrees/test -b sandbox-test");
    process.chdir(join(repo, ".worktrees", "test"));
    writeFileSync("tracked.txt", "worktree\n");
    await run("git add tracked.txt && git -c user.name=test -c user.email=test@example.com commit -m worktree");
    assert.equal((await run("git log -1 --format=%s")).trim(), "worktree");
  } finally {
    await SandboxManager.reset();
    process.chdir(originalCwd);
    rmSync(root, { recursive: true, force: true });
  }
});
