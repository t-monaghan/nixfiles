/**
 * Status Line Extension
 *
 * Adds segments to pi's default footer to match claude-code-status-line.sh.
 * Only adds what the default footer doesn't already show:
 * dir, git branch/status, AWS profile, sandbox status.
 *
 * The default footer already shows: tokens, cost, context %, model.
 * Overrides the verbose sandbox extension status with a compact claude-code style indicator.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { basename, join } from "node:path";

function git(cwd: string, args: string): string | null {
	try {
		return execSync(
			`git -C ${JSON.stringify(cwd)} -c core.useBuiltinFSMonitor=false -c core.fsmonitor=false ${args}`,
			{ encoding: "utf8", timeout: 2000, stdio: ["pipe", "pipe", "pipe"] },
		).trim();
	} catch {
		return null;
	}
}

function buildStatus(ctx: any, theme: any): string {
	const cwd = ctx.cwd;
	const parts: string[] = [];

	// Directory name
	parts.push(theme.fg("accent", basename(cwd)));

	// Git branch + status
	if (git(cwd, "rev-parse --git-dir") !== null) {
		const branch = git(cwd, "rev-parse --abbrev-ref HEAD");
		if (branch) {
			parts.push(theme.fg("warning", ` ${branch}`));
		}

		const status = git(cwd, "status --porcelain");
		if (status) {
			const lines = status.split("\n").filter(Boolean);
			const mod = lines.filter((l) => /^ M|^M/.test(l)).length;
			const unt = lines.filter((l) => /^\?\?/.test(l)).length;
			const stg = lines.filter((l) => /^[MADRC]/.test(l)).length;
			const st: string[] = [];
			if (mod > 0) st.push(`󰏫 (${mod})`);
			if (unt > 0) st.push(`󰊇 (${unt})`);
			if (stg > 0) st.push("󰶍");
			if (st.length) parts.push(theme.fg("warning", st.join(" ")));
		}
	}

	// AWS profile/region
	const grantedRole = process.env.GRANTED_SSO_ROLE_NAME;
	const awsProfile = process.env.AWS_PROFILE;
	const awsKey = process.env.AWS_ACCESS_KEY_ID;
	if (grantedRole || awsProfile || awsKey) {
		const profile = grantedRole || awsProfile || "assumed";
		const region = process.env.AWS_REGION ? ` (${process.env.AWS_REGION})` : "";
		parts.push(theme.fg("accent", `│ 󰅟 ${profile}${region}`));
	}

	// Sandbox status — compact indicator (overrides verbose sandbox extension output)
	let sandboxed = false;
	try {
		const paths = [
			join(process.env.HOME || "~", ".pi", "agent", "sandbox.json"),
			join(cwd, ".pi", "sandbox.json"),
		];
		for (const p of paths) {
			if (existsSync(p)) {
				const cfg = JSON.parse(readFileSync(p, "utf8"));
				if (cfg?.enabled === true) {
					sandboxed = true;
					break;
				}
			}
		}
	} catch {}
	parts.push(
		sandboxed ? theme.fg("success", "│ 󰒃 sandbox") : theme.fg("error", "│ ✗ sandbox"),
	);

	return parts.join(" ");
}

export default function (pi: ExtensionAPI) {
	function update(ctx: any) {
		try {
			const theme = ctx.ui.theme;
			ctx.ui.setStatus("status-line", buildStatus(ctx, theme));
			// Hide verbose status from pi-mcp-adapter and pi-sandbox
			ctx.ui.setStatus("mcp", undefined);
			ctx.ui.setStatus("sandbox", undefined);
		} catch {}
	}

	pi.on("session_start", async (_event, ctx) => {
		// Delay to ensure package extensions have set their status first
		setTimeout(() => update(ctx), 2000);
	});
	pi.on("turn_start", async (_event, ctx) => update(ctx));
	pi.on("turn_end", async (_event, ctx) => update(ctx));
	pi.on("session_switch", async (_event, ctx) => update(ctx));
}
