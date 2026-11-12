import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const filter = resolve("modules/tools/rex/worktree-rows.jq");
const worktrees = { schema: 2, items: [
  { branch: "main", worktree: { path: "/repo", main: true } },
  { branch: "feature", worktree: { path: "/repo/.worktrees/feature" }, head: { subject: "Fix feature" } },
  { branch: "old", worktree: { path: "/repo/.worktrees/pr-77" } },
  { branch: "branch-only", worktree: null },
  { branch: "fork:refs/pull/42/head", worktree: { path: "/repo/.worktrees/fork" } },
] };
const prs = [
  { number: 12, headRefName: "feature", state: "OPEN", title: "Feature", updatedAt: "2026-01-02" },
  { number: 13, headRefName: "new", state: "OPEN", title: "New PR", updatedAt: "2026-01-03" },
  { number: 14, headRefName: "closed", state: "MERGED", title: "Closed PR", updatedAt: "2026-01-01" },
  { number: 42, headRefName: "fork", state: "OPEN", title: "Fork", updatedAt: "2026-01-01" },
];

function rows(pulls = prs) {
  const result = spawnSync("jq", ["-r", "--argjson", "prs", JSON.stringify(pulls), "-f", filter], {
    input: JSON.stringify(worktrees), encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trimEnd().split("\n");
}

test("worktree rows show PR numbers without moving branch-named directories", () => {
  const result = rows();
  assert.equal(result.length, 5);
  assert(result.includes("wt\t/repo/.worktrees/feature\t12\t#12 feature\t\tFix feature"));
  assert(result.some(row => row.startsWith("wt\t/repo/.worktrees/pr-77\t77\t#77 old")));
  assert(result.some(row => row.startsWith("wt\t/repo/.worktrees/fork\t42\t#42 fork")));
  assert(result.includes("pr\t13\t13\t#13 new\topen PR\tNew PR"));
  assert(!result.some(row => row.startsWith("pr\t12\t") || row.startsWith("pr\t42\t")));
});

test("worktree rows retain directory PR numbers when GitHub is unavailable", () => {
  const result = rows([]);
  assert.equal(result.length, 4);
  assert(result.some(row => row.startsWith("wt\t/repo/.worktrees/pr-77\t77\t#77 old")));
  assert(result.some(row => row.startsWith("wt\t/repo/.worktrees/feature\t-\tfeature")));
});

test("worktree rows use PR numbers for merged PRs too", () => {
  assert(rows([{ ...prs[0], state: "MERGED" }]).some(row => row.includes("\t#12 feature\t")));
});

for (const kind of ["wt", "pr", "cancel-repo", "cancel-worktree", "github-unavailable", "current-repo", "current-worktree", "not-a-repo", "search-repo", "search-hidden-prefix"]) {
  test(`worktree picker: ${kind}`, { skip: !process.env.PI_SESSION_TEMP }, () => {
    const dir = mkdtempSync(join(process.env.PI_SESSION_TEMP, "rex-worktree-test-"));
    const home = join(dir, "home");
    const repo = join(home, "dev", "repo with spaces");
    mkdirSync(repo, { recursive: true });
    const currentRoot = kind === "current-worktree" ? join(repo, ".worktrees/feature") : repo;
    const current = join(currentRoot, "src");
    mkdirSync(current, { recursive: true });
    const entries = structuredClone(worktrees);
    entries.items[0].worktree.path = repo;
    try {
      const scripts = {
        zoxide: 'printf "%s\\n" /another/repo "$MOCK_REPO" "$MOCK_ROOT"',
        git: 'if [[ "$*" == *rev-parse* ]]; then if [[ "$1" == -C ]]; then [[ "$MOCK_KIND" != not-a-repo ]] || exit 1; printf "%s\\n" "$MOCK_ROOT"; else pwd; fi; else printf "%s\\n" feature; fi',
        wt: 'if [[ "$MOCK_KIND" == current-* ]]; then [[ "$PWD" == "$MOCK_ROOT" ]] || exit 99; fi; printf "%s\\n" "$MOCK_WORKTREES"',
        gh: '[[ "$MOCK_KIND" != github-unavailable ]] || exit 1; printf "%s\\n" "$MOCK_PRS"',
        fish: 'printf \'{"path":"/repo/.worktrees/pr-13"}\\n\'',
        rex: 'printf "%s\\n" "$@"',
        fzf: `input=$(/bin/cat)
if [[ "$*" == *'--prompt=repo> '* ]]; then
  [[ "$MOCK_KIND" != cancel-repo ]] || exit 130
  [[ "$*" == *'--with-nth=2..'* ]] || exit 99
  if [[ "$MOCK_KIND" == search-repo ]]; then
    printf '%s\\n' "$input" | "$REAL_FZF" "$@" --filter='repo with spaces'
    exit $?
  elif [[ "$MOCK_KIND" == search-hidden-prefix ]]; then
    printf '%s\\n' "$input" | "$REAL_FZF" "$@" --filter="$HOME/dev/"
    exit $?
  fi
  expected_repo="$MOCK_REPO"$'\\t'"repo with spaces"
  [[ "$(printf '%s\\n' "$input" | grep -Fxc "$expected_repo")" == 1 ]] || exit 99
  if [[ "$MOCK_KIND" == current-* ]]; then
    expected_root="$MOCK_ROOT"$'\\t'"\${MOCK_ROOT#"$HOME/dev/"}"
    [[ "$(printf '%s\\n' "$input" | head -n 1)" == "$expected_root" ]] || exit 99
    [[ "$(printf '%s\\n' "$input" | grep -Fxc "$expected_root")" == 1 ]] || exit 99
    printf '%s\\n' "$expected_root"
  else
    [[ "$(printf '%s\\n' "$input" | head -n 1)" == $'/another/repo\\t/another/repo' ]] || exit 99
    printf '%s\\n' "$expected_repo"
  fi
else
  [[ "$MOCK_KIND" != cancel-worktree ]] || exit 130
  if [[ "$MOCK_KIND" == pr ]]; then
    printf '%s\\n' "$input" | grep -F $'pr\\t13\\t'
  else
    printf '%s\\n' "$input" | grep -F $'wt\\t/repo/.worktrees/feature\\t'
  fi
fi`,
      };
      for (const [name, script] of Object.entries(scripts)) {
        writeFileSync(join(dir, name), `#!/bin/bash\nset -eu\n${script}\n`, { mode: 0o755 });
      }
      const args = ["-euo", "pipefail", "modules/tools/rex/pick-worktree.sh", "client:origin"];
      if (kind.startsWith("current-") || kind === "not-a-repo") args.push(current);
      const result = spawnSync("bash", args, {
        encoding: "utf8", input: "\n",
        env: { ...process.env, HOME: home, PATH: `${dir}:${process.env.PATH}`, REX_WORKTREE_ROWS: filter,
          MOCK_KIND: kind, MOCK_REPO: repo, MOCK_ROOT: currentRoot, MOCK_WORKTREES: JSON.stringify(entries), MOCK_PRS: JSON.stringify(prs),
          REAL_FZF: spawnSync("bash", ["-c", "command -v fzf"], { encoding: "utf8" }).stdout.trim(),
          FZF_DEFAULT_OPTS: "", FZF_DEFAULT_OPTS_FILE: "/dev/null" },
      });
      assert.equal(result.status, 0, result.stderr);
      if (kind.startsWith("cancel") || kind === "search-hidden-prefix") {
        assert.equal(result.stdout, "");
      } else {
        const number = kind === "pr" ? 13 : 12;
        const path = kind === "pr" ? "/repo/.worktrees/pr-13" : "/repo/.worktrees/feature";
        const name = kind === "github-unavailable" ? "repo with spaces: feature" : `repo with spaces #${number}`;
        assert.equal(result.stdout, `--autostart=false\n--client\nclient:origin\ndo\nopen_worktree\nname=${name}\npath=${path}\n`);
      }
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
