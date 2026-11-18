import assert from "node:assert/strict";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";

export function omniwmSettings() {
  const result = spawnSync("nix-instantiate", ["--eval", "--strict", "--json", "--expr", `
    (import ${JSON.stringify(resolve("modules/tools/omniwm.nix"))} {
      config.nixfiles.context.role.desktop = true;
      lib = {
        mkIf = condition: value: if condition then value else {};
        range = first: last: builtins.genList (index: first + index) (last - first + 1);
      };
    }).programs.omniwm.settings
  `], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
  return JSON.parse(result.stdout);
}
