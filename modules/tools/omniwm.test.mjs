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

test("OmniWM uses schema 5 and preserves the resize shortcuts", () => {
  const { schemaVersion, hotkeys } = omniwmSettings();
  assert.equal(schemaVersion, 5);
  assert.deepEqual(
    hotkeys.filter(({ id }) => /^resize(?:Container|Window)(?:Primary|Secondary)Span\./.test(id)),
    [
      { binding: "Option+Minus", id: "resizeContainerPrimarySpan.shrink" },
      { binding: "Option+Equal", id: "resizeContainerPrimarySpan.grow" },
      { binding: "Unassigned", id: "resizeWindowPrimarySpan.shrink" },
      { binding: "Unassigned", id: "resizeWindowPrimarySpan.grow" },
      { binding: "Option+Shift+Minus", id: "resizeWindowSecondarySpan.shrink" },
      { binding: "Option+Shift+Equal", id: "resizeWindowSecondarySpan.grow" },
    ],
  );
  assert(!hotkeys.some(({ id }) => /\.(?:decrease|increase)10Percent$/.test(id)));
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
