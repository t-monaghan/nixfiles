import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";

type Mode = "plan" | "execute";

const modes: Mode[] = ["plan", "execute"];
const instructions: Record<Mode, string> = {
  plan: "PLAN: Investigate and propose a plan. Do not edit code or change state, even if asked to. Temporary files for investigation are permitted.",
  execute: "EXECUTE: Make the requested changes. Edit code and run checks when needed.",
};

export default function modeExtension(pi: ExtensionAPI): void {
  let mode: Mode = "execute";

  function setMode(next: Mode, ctx: ExtensionContext): void {
    mode = next;
    pi.appendEntry("mode", { mode });
    ctx.ui.setStatus("zz-mode", mode === "plan" ? "[plan]" : undefined);
    ctx.ui.notify(`Mode: ${mode}`, "info");
  }

  pi.registerCommand("mode", {
    description: "Select plan or execute mode",
    handler: async (args, ctx) => {
      const arg = args.trim().toLowerCase();
      if (!arg) {
        if (!ctx.hasUI) return;
        const choice = await ctx.ui.select("Mode:", modes);
        if (choice) setMode(choice as Mode, ctx);
      } else if (modes.includes(arg as Mode)) {
        setMode(arg as Mode, ctx);
      } else {
        ctx.ui.notify(`Unknown mode "${arg}". Use plan or execute.`, "warning");
      }
    },
  });

  pi.registerShortcut("ctrl+p", {
    description: "Toggle plan/execute mode",
    handler: async (ctx) => setMode(mode === "plan" ? "execute" : "plan", ctx),
  });

  pi.on("before_agent_start", async () => ({
    message: {
      customType: "mode-instruction",
      content: `<system-message>\n${instructions[mode]}\n</system-message>`,
      display: false,
    },
  }));

  pi.on("session_start", async (_event, ctx) => {
    mode = "execute";
    for (const entry of [...ctx.sessionManager.getBranch()].reverse()) {
      if (entry.type === "custom" && entry.customType === "mode") {
        const saved = (entry.data as { mode?: Mode }).mode;
        if (saved && modes.includes(saved)) mode = saved;
        break;
      }
    }
    ctx.ui.setStatus("zz-mode", mode === "plan" ? "[plan]" : undefined);
    if (ctx.mode === "tui") {
      ctx.ui.setEditorComponent((tui, theme, keybindings) => new (class extends CustomEditor {
        render(width: number): string[] {
          if (mode !== "plan") return super.render(width);
          const originalBorderColor = this.borderColor;
          this.borderColor = (text) => ctx.ui.theme.fg("borderAccent", text);
          try {
            return super.render(width);
          } finally {
            this.borderColor = originalBorderColor;
          }
        }
      })(tui, theme, keybindings));
    }
  });
}
