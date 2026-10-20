import { test } from "node:test";
import { strict as assert } from "node:assert";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const config = resolve(import.meta.dirname, "hud.nix");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}

test("buildkite lists builds, not jobs, and colors build and pi session states", () => {
  const expression = `import ${JSON.stringify(config)} {
    config.nixfiles.work.cultureAmp.enable = true;
    lib = {
      optionalAttrs = condition: value: if condition then value else {};
      optionals = condition: value: if condition then value else [];
    };
  }`;
  const hud = JSON.parse(run("nix-instantiate", ["--eval", "--strict", "--json", "--expr", expression]));
  assert.deepEqual(hud.recipe.builds.columns, ["repo/project", "status", "branch", "commit message"]);
  assert.equal(hud.recipe.builds.colors.status.passed, "green");
  assert.equal(hud.recipe.builds.colors.status.failed, "red");
  assert.equal(hud.recipe["pi-sessions"].colors.state.Waiting, "yellow");
  assert.equal(hud.recipe["pi-sessions"].colors.state.Working, "green");

  const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "hud-test-"));
  try {
    const bin = join(dir, "bk"), log = join(dir, "bk-args");
    writeFileSync(bin, `#!/bin/sh\nprintf '%s\\n' "$*" > "$HUD_BK_ARGS"\nprintf '%s\\n' '[{"pipeline":{"slug":"example"},"state":"running","branch":"feature","message":"First line\\nSecond line","web_url":"https://example.test/1","jobs":[{"name":"job a"},{"name":"job b"}]},{"pipeline":{"slug":"example"},"state":"passed","branch":"main","message":"Release","web_url":"https://example.test/2","jobs":[{"name":"job c"}]}]'\n`, { mode: 0o755 });
    const rows = JSON.parse(run("sh", ["-c", hud.recipe.builds.command], {
      env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, HUD_BK_ARGS: log },
    }));
    assert.deepEqual(rows, [
      { "repo/project": "example", status: "running", branch: "feature", "commit message": "First line", url: "https://example.test/1" },
      { "repo/project": "example", status: "passed", branch: "main", "commit message": "Release", url: "https://example.test/2" },
    ]);
    assert.match(readFileSync(log, "utf8"), /--limit 50 --json/);
    assert.doesNotMatch(readFileSync(log, "utf8"), /--state=running|--no-limit/);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
