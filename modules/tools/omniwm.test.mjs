import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { omniwmSettings } from "./omniwm/settings.test-helper.mjs";

const config = readFileSync("modules/tools/omniwm.nix", "utf8");

test("OmniWM has six workspaces and leaves workspace 7 shortcuts unassigned", () => {
  const { workspaces, hotkeys } = omniwmSettings();
  assert.deepEqual(workspaces.map(workspace => workspace.name), ["1", "2", "3", "4", "5", "6"]);
  for (const id of ["switchWorkspace.6", "moveToWorkspace.6"]) {
    assert.equal(hotkeys.find(hotkey => hotkey.id === id).binding, "Unassigned");
  }
  assert(!hotkeys.some(hotkey => ["Option+7", "Option+U"].includes(hotkey.binding)));
  assert.equal(hotkeys.find(hotkey => hotkey.id === "moveToWorkspace.5").binding, "Option+Y");
});

test("OmniWM does not run Huddle workspace-follow automation", () => {
  assert.doesNotMatch(config, /followHuddle|follow-huddle|active-workspace,focused-monitor,windows-changed/);
});

test("Rex uses tiling while the workspace bar still hides floating windows", () => {
  assert.match(config, /\{\s*bundleId = "com\.superlogical\.rex";\s*layout = "tile";\s*\}/);
  assert.match(config, /showFloatingWindows = false;/);
});

test("Slack stays assigned to workspace 3 and Huddle windows use tiling", () => {
  assert.match(config, /bundleId = "com\.tinyspeck\.slackmacgap";\s+assignToWorkspace = "3";/);
  assert.match(config, /titleRegex = huddleTitleRegex;\s+layout = "tile";\s+assignToWorkspace = "3";/);
});
