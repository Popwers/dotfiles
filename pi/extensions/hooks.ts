import { execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { basename, dirname, extname, join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

type NotifyContext = {
	ui: {
		notify(message: string, level: "info" | "error"): void;
	};
};

export default function (pi: ExtensionAPI) {
	// ─── Session Start ───────────────────────────────────────────────
	pi.on("session_start", async (_event, ctx) => {
		// Start ollama if not running
		try {
			execSync("pgrep -x ollama", { timeout: 3000 });
		} catch {
			execSync("nohup ollama serve > /dev/null 2>&1 &", { timeout: 5000 });
			ctx.ui.notify("Started ollama", "info");
		}

		// Start grepai if available
		try {
			execSync("command -v grepai", { timeout: 3000 });
			try {
				execSync("grepai status", { timeout: 5000, stdio: "pipe" });
			} catch {
				execSync("grepai init --yes", { timeout: 10000, stdio: "pipe" });
			}
			// Ensure .grepai/ in gitignore
			const gitignore = join(ctx.cwd, ".gitignore");
			if (existsSync(gitignore)) {
				const content = readFileSync(gitignore, "utf-8");
				if (!content.split("\n").includes(".grepai/")) {
					writeFileSync(
						gitignore,
						content.endsWith("\n")
							? `${content}.grepai/\n`
							: `${content}\n.grepai/\n`,
					);
				}
			}
			execSync("grepai watch --background", { timeout: 10000, stdio: "pipe" });
			ctx.ui.notify("GrepAI watcher started", "info");
		} catch {
			// grepai not installed, skip
		}

		// Ensure .claudeignore from template
		const home = process.env.HOME;
		if (home) {
			const template = join(home, ".claude", "claudeignore.template");
			const target = join(ctx.cwd, ".claudeignore");
			if (existsSync(template)) {
				if (!existsSync(target)) {
					copyFileSync(template, target);
				} else {
					// Merge missing lines
					const templateLines = readFileSync(template, "utf-8").split("\n");
					const targetContent = readFileSync(target, "utf-8");
					for (const line of templateLines) {
						if (!line || line.startsWith("#")) continue;
						if (!targetContent.split("\n").includes(line)) {
							appendFileSync(target, `${line}\n`);
						}
					}
				}
			}
		}
	});

	// ─── Tool Call Gates ─────────────────────────────────────────────
	pi.on("tool_call", async (event, _ctx) => {
		if (isToolCallEventType("bash", event)) {
			const cmd = event.input.command;

			// Block --no-verify on git commit/push
			const stripped = cmd.replace(
				/(-m|--message)\s+((?:"[^"]*")|(?:'[^']*')|\S+)/g,
				"",
			);
			if (
				/\bgit\s+.*\b(commit|push)\b.*--no-verify|\bgit\s+.*--no-verify\b.*\b(commit|push)\b/.test(
					stripped,
				)
			) {
				return {
					block: true,
					reason:
						"Blocked: --no-verify bypasses husky hooks (tests, biome, commitlint). Remove the flag and fix the underlying issue.",
				};
			}

			// Block dangerous commands (matching Claude Code deny list)
			const dangerPatterns = [
				/\brm\s+(-rf|-r\s+-f|-f\s+-r)\b/,
				/\bsudo\s+/,
				/\bsu\s+/,
				/\bdoas\s+/,
				/\bchmod\s+777\b/,
				/\bgit\s+push\s+(-f\b|--force\b|--force-with-lease\b)/,
				/\bgit\s+reset\s+--hard\b/,
				/\bcurl\s+.*\|\s*(sh|bash|fish|zsh)\b/,
				/\bwget\s+.*\|\s*(sh|bash|fish|zsh)\b/,
			];
			for (const pattern of dangerPatterns) {
				if (pattern.test(cmd)) {
					return {
						block: true,
						reason: `Blocked: dangerous command pattern detected (${pattern.source}). This is blocked by your security policy.`,
					};
				}
			}

			// rtk hook (if available)
			try {
				execSync("command -v rtk", { timeout: 3000, stdio: "pipe" });
				// rtk hook claude — runs inline, modifies nothing if no match
				execSync(`rtk hook claude`, {
					timeout: 5000,
					stdio: "pipe",
					env: { ...process.env, TOOL_INPUT: JSON.stringify({ command: cmd }) },
				});
			} catch {
				// rtk not installed, skip
			}
		}
	});

	// ─── Post Tool Result (auto-format, typecheck, tests) ───────────
	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName !== "edit" && event.toolName !== "write") return;

		const filePath = inputPath(event.input);
		if (!filePath) return;

		const ext = extname(filePath);
		const isFrontend = /\.(tsx?|jsx?|css|astro|svelte|vue|html)$/i.test(ext);
		const isTS = /\.(ts|tsx)$/i.test(ext);

		if (!existsSync(filePath)) return;

		// Auto-format with Biome for JS/TS/JSON/CSS files
		if (/\.(ts|tsx|js|jsx|json|css)$/i.test(ext)) {
			let dir = dirname(filePath);
			while (dir !== "/") {
				if (
					existsSync(join(dir, "biome.json")) ||
					existsSync(join(dir, "biome.jsonc"))
				) {
					try {
						execSync(
							`bunx @biomejs/biome check --write "${filePath}" --no-errors-on-unmatched`,
							{
								timeout: 10000,
								cwd: dir,
								stdio: "pipe",
							},
						);
					} catch (error) {
						const output = errorOutput(error);
						const tail = output.split("\n").slice(-5).join("\n");
						ctx.ui.notify(
							`[Biome] Issues in ${basename(filePath)}: ${tail}`,
							"error",
						);
					}
					break;
				}
				dir = dirname(dir);
			}
		}

		// Check for unsafe any assertions in TS files
		if (isTS) {
			try {
				const content = readFileSync(filePath, "utf-8");
				if (/\bas\s+any\b/.test(content)) {
					ctx.ui.notify(
						`[Types] Unsafe any assertion found in ${basename(filePath)}. Replace it with a type guard or typed helper.`,
						"error",
					);
				}
			} catch {
				// ignore
			}
		}

		// TypeScript check
		if (isTS) {
			let dir = dirname(filePath);
			while (dir !== "/") {
				if (existsSync(join(dir, "tsconfig.json"))) {
					try {
						const errors = execSync(`bunx tsc --noEmit --pretty 2>&1`, {
							timeout: 30000,
							cwd: dir,
							stdio: "pipe",
						}).toString();
						const errorLines = errors
							.split("\n")
							.filter((l) => /error TS/.test(l))
							.slice(0, 10);
						if (errorLines.length > 0) {
							ctx.ui.notify(
								`[TypeCheck] ${errorLines.length} error(s):\n${errorLines.join("\n")}`,
								"error",
							);
						}
					} catch (error) {
						const output = errorOutput(error);
						const errorLines = output
							.split("\n")
							.filter((l: string) => /error TS/.test(l))
							.slice(0, 10);
						if (errorLines.length > 0) {
							ctx.ui.notify(
								`[TypeCheck] ${errorLines.length} error(s):\n${errorLines.join("\n")}`,
								"error",
							);
						}
					}
					break;
				}
				dir = dirname(dir);
			}
		}

		// Run related tests (async — don't block)
		if (/\.(ts|tsx|js|jsx)$/i.test(ext)) {
			runRelatedTests(filePath, ctx).catch(() => {});
		}

		// Impeccable check for frontend files
		if (isFrontend) {
			try {
				execSync("command -v impeccable", { timeout: 3000, stdio: "pipe" });
				try {
					const output = execSync(`impeccable detect "${filePath}"`, {
						timeout: 15000,
						stdio: "pipe",
					}).toString();
					if (output.trim()) {
						ctx.ui.notify(
							`[Impeccable] UI anti-patterns in ${basename(filePath)}:\n${output}`,
							"error",
						);
					}
				} catch (error) {
					const output = errorOutput(error);
					if (output.trim()) {
						ctx.ui.notify(
							`[Impeccable] UI anti-patterns in ${basename(filePath)}:\n${output}`,
							"error",
						);
					}
				}
			} catch {
				// impeccable not installed, skip
			}
		}
	});

	// ─── Agent End (stop quality check) ──────────────────────────────
	pi.on("agent_end", async (_event, ctx) => {
		// Stop grepai watcher
		try {
			execSync("command -v grepai", { timeout: 3000, stdio: "pipe" });
			execSync("grepai watch --stop", { timeout: 10000, stdio: "pipe" });
		} catch {
			// skip
		}

		// Quality gate on modified files
		const cwd = ctx.cwd;
		let repoRoot: string | undefined;
		try {
			repoRoot = execSync("git rev-parse --show-toplevel", {
				timeout: 5000,
				cwd,
				stdio: "pipe",
			})
				.toString()
				.trim();
		} catch {
			return; // not a git repo
		}
		if (!repoRoot) return;
		const root = repoRoot;

		// Get modified/new JS/TS files
		const modified: string[] = [];
		try {
			const diffOutput = execSync("git diff --name-only HEAD -z", {
				cwd: repoRoot,
				stdio: "pipe",
				timeout: 5000,
			}).toString();
			const untrackedOutput = execSync(
				"git ls-files --others --exclude-standard -z",
				{
					cwd: repoRoot,
					stdio: "pipe",
					timeout: 5000,
				},
			).toString();

			const allFiles = [
				...diffOutput.split("\0"),
				...untrackedOutput.split("\0"),
			].filter(Boolean);
			for (const rel of allFiles) {
				if (/\.(ts|tsx|js|jsx)$/.test(rel)) {
					const abs = join(root, rel);
					if (existsSync(abs)) modified.push(abs);
				}
			}
		} catch {
			return;
		}

		if (modified.length === 0) return;

		const issues: string[] = [];

		// Run tests on modified test files
		for (const f of modified) {
			if (!/\.test\.(ts|tsx|js|jsx)$/.test(f)) continue;
			try {
				execSync(`bun test "${f}"`, {
					cwd: repoRoot,
					timeout: 30000,
					stdio: "pipe",
				});
			} catch (error) {
				const output = errorOutput(error);
				const failures = output
					.split("\n")
					.filter((l: string) => /FAIL|Error|[✗×]/.test(l))
					.slice(0, 5);
				issues.push(
					`[Tests] Failures in ${basename(f)}:\n${failures.join("\n")}`,
				);
			}
		}

		// Biome lint check
		try {
			execSync("command -v bunx", { timeout: 3000, stdio: "pipe" });
			try {
				execSync(
					`bunx @biomejs/biome check ${modified.map((f) => `"${f}"`).join(" ")} --no-errors-on-unmatched`,
					{
						cwd: repoRoot,
						timeout: 30000,
						stdio: "pipe",
					},
				);
			} catch (error) {
				const output = errorOutput(error);
				const lines = output
					.split("\n")
					.filter((l: string) => /error|warning/.test(l))
					.slice(0, 5);
				if (lines.length > 0) {
					issues.push(`[Lint] Fix before completing:\n${lines.join("\n")}`);
				}
			}
		} catch {
			// bunx not installed
		}

		if (issues.length > 0) {
			ctx.ui.notify(`Task quality issues:\n${issues.join("\n\n")}`, "error");
		}
	});
}

// ─── Helpers ────────────────────────────────────────────────────────

async function runRelatedTests(filePath: string, ctx: NotifyContext) {
	const base = basename(filePath);

	let testFile: string | undefined;
	if (/\.test\.(ts|tsx|js|jsx)$/.test(base)) {
		testFile = filePath;
	} else {
		const name = base.replace(/\.[^.]+$/, "");
		// Search in tests/ directory
		let dir = dirname(filePath);
		while (dir !== "/") {
			if (existsSync(join(dir, "package.json"))) {
				try {
					const result = execSync(
						`find "${join(dir, "tests")}" -name "${name}.test.*" 2>/dev/null | head -1`,
						{ timeout: 5000, stdio: "pipe" },
					)
						.toString()
						.trim();
					if (result && existsSync(result)) {
						testFile = result;
					}
				} catch {
					// no tests dir
				}
				break;
			}
			dir = dirname(dir);
		}
	}

	if (testFile && existsSync(testFile)) {
		try {
			execSync(`bun test "${testFile}"`, { timeout: 30000, stdio: "pipe" });
		} catch (error) {
			const output = errorOutput(error);
			const failures = output
				.split("\n")
				.filter((l: string) => /FAIL|Error|[✗×]/.test(l))
				.slice(0, 10);
			if (failures.length > 0) {
				ctx.ui.notify(
					`[Tests] Failures in ${basename(testFile)}:\n${failures.join("\n")}`,
					"error",
				);
			}
		}
	}
}

// Minimal fs helpers to avoid top-level import issues in some environments
function copyFileSync(src: string, dest: string) {
	writeFileSync(dest, readFileSync(src));
}

function appendFileSync(path: string, data: string) {
	const existing = existsSync(path) ? readFileSync(path, "utf-8") : "";
	writeFileSync(path, existing + data);
}

function inputPath(input: unknown): string | undefined {
	if (!input || typeof input !== "object") return undefined;
	const path = (input as Record<string, unknown>).path;
	return typeof path === "string" ? path : undefined;
}

function errorOutput(error: unknown): string {
	if (!error || typeof error !== "object") return "";
	const record = error as Record<string, unknown>;
	return outputValue(record.stdout) + outputValue(record.stderr);
}

function outputValue(value: unknown): string {
	if (!value) return "";
	if (typeof value === "string") return value;
	if (Buffer.isBuffer(value)) return value.toString();
	if (typeof value === "object" && "toString" in value) return value.toString();
	return "";
}
