import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import * as path from "node:path";
import { compileFunction } from "node:vm";
import test from "node:test";

const source = stripTypeScriptTypes(readFileSync(new URL("./index.ts", import.meta.url), "utf8"))
  .replace(/import\s*\{([^}]+)\}\s*from\s*"([^"]+)";/g, (_, names, module) =>
    `const {${names}} = modules[${JSON.stringify(module)}];`)
  .replace("export default function", "return function");
const load = compileFunction(source, ["modules", "process"]);

function setup({ mode = "tui", failure } = {}) {
  const handlers = {};
  const events = [];
  const dialogs = [];
  let askNetwork;
  class Component {
    addChild() {}
    render() { return []; }
    invalidate() {}
    handleInput(data) {
      if (data === "\u001b") this.onCancel();
      if (data === "\r") this.onSelect({ value: "session" });
    }
  }
  const activate = load({
    "node:child_process": {},
    "node:fs": { existsSync: () => false, realpathSync: { native: (value) => value } },
    "node:os": { homedir: () => "/home/test" },
    "node:path": path,
    "@anthropic-ai/sandbox-runtime": {
      SandboxManager: {
        initialize: async (_config, ask) => { askNetwork = ask; },
        reset: async () => {},
      },
    },
    "@earendil-works/pi-coding-agent": {
      createBashTool: () => ({}),
      DynamicBorder: Component,
      getAgentDir: () => "/home/test/.pi/agent",
      getShellConfig: () => ({ shell: "bash" }),
      isToolCallEventType: (name, event) => name === event.toolName,
      SettingsManager: { create: () => ({ getShellCommandPrefix: () => undefined }) },
    },
    "@earendil-works/pi-tui": { Container: Component, SelectList: Component, Text: Component },
  }, { cwd: () => "/project", platform: "linux" });
  activate({
    on: (name, handler) => { handlers[name] = handler; },
    registerTool() {},
    registerCommand() {},
    events: { emit: (name, payload) => events.push({ name, payload }) },
  });
  const ctx = {
    mode,
    hasUI: true,
    ui: {
      notify() {},
      setStatus() {},
      custom(factory, options) {
        if (failure) return Promise.reject(failure);
        return new Promise((resolve) => {
          const component = factory({ requestRender() {} }, { fg: (_color, text) => text, bold: (text) => text }, {}, resolve);
          dialogs.push({ component, options });
        });
      },
      select: async () => undefined,
    },
  };
  return { handlers, events, dialogs, ctx, network: (host) => askNetwork({ host }) };
}

for (const key of ["a", "d", "\u001b", "\r"]) {
  test(`permission dialog declares blocked status and closes for ${JSON.stringify(key)}`, async () => {
    const { handlers, ctx, dialogs, events } = setup();
    await handlers.session_start({}, ctx);
    const pending = handlers.tool_call({ toolName: "read", input: { path: "/outside/file" } }, ctx);
    assert.equal(dialogs.length, 1);
    assert.deepEqual(dialogs[0].options, {
      blocked: { kind: "permission", message: '📖 Allow read of "/outside/file"?' },
    });
    dialogs[0].component.handleInput(key);
    const result = await pending;
    assert.equal(result?.block, key === "a" || key === "\r" ? undefined : true);
    assert.equal(events.at(-1).name, "attention:resolve");
    assert.equal(events[0].payload.key, events.at(-1).payload.key);
  });
}

test("queued network prompts each declare their own permission status", async () => {
  const { handlers, ctx, network, dialogs } = setup();
  await handlers.session_start({}, ctx);
  const first = network("first.example");
  const second = network("second.example");
  await Promise.resolve();
  assert.equal(dialogs.length, 1);
  assert.deepEqual(dialogs[0].options.blocked, {
    kind: "permission", message: '🌐 Allow network connection to "first.example"?',
  });
  dialogs[0].component.handleInput("a");
  assert.equal(await first, true);
  await Promise.resolve();
  assert.equal(dialogs.length, 2);
  assert.deepEqual(dialogs[1].options.blocked, {
    kind: "permission", message: '🌐 Allow network connection to "second.example"?',
  });
  dialogs[1].component.handleInput("d");
  assert.equal(await second, false);
});

test("dialog failure still resolves the attention request", async () => {
  const failure = new Error("dialog failed");
  const { handlers, ctx, events } = setup({ failure });
  await handlers.session_start({}, ctx);
  await assert.rejects(handlers.tool_call({ toolName: "read", input: { path: "/outside/file" } }, ctx), failure);
  assert.equal(events.at(-1).name, "attention:resolve");
});

test("non-TUI permission requests retain the built-in selector fallback", async () => {
  const { handlers, ctx, dialogs } = setup({ mode: "rpc" });
  await handlers.session_start({}, ctx);
  const result = await handlers.tool_call({ toolName: "read", input: { path: "/outside/file" } }, ctx);
  assert.equal(result.block, true);
  assert.equal(dialogs.length, 0);
});
