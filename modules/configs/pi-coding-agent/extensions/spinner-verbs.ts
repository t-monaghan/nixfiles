/**
 * Spinner Verbs Extension
 *
 * Rotates the working message through a curated list of verbs on every
 * agent turn, matching the Claude Code `spinnerVerbs` config. Source list
 * lives in `modules/configs/spinner-verbs.json` and is shared with the
 * Claude Code config.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const VERBS_PATH = join(__dirname, "..", "spinner-verbs.json");

let verbs: string[] = [];
try {
  verbs = JSON.parse(readFileSync(VERBS_PATH, "utf8"));
} catch {
  verbs = [];
}

function pickVerb(): string {
  if (verbs.length === 0) return "Working...";
  return verbs[Math.floor(Math.random() * verbs.length)]!;
}

export default function (pi: ExtensionAPI) {
  if (verbs.length === 0) return;

  const apply = (ctx: ExtensionContext) => {
    ctx.ui.setWorkingMessage(`${pickVerb()}...`);
  };

  pi.on("session_start", async (_event, ctx) => apply(ctx));
  pi.on("turn_start", async (_event, ctx) => apply(ctx));
}
