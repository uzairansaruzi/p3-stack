// Render the sync pull-request body from the detect report, Claude
// dispositions, and the validation result. Writes markdown to stdout.
// Usage: node scripts/upstream/render-pr-body.mjs --report <detect.json>
//        [--dispositions <dispositions.json>] [--validation <result.json>]
//        --mode adapted|report-only
import { readFileSync } from "node:fs";

const args = process.argv.slice(2);
function arg(name) {
  const i = args.indexOf(`--${name}`);
  return i === -1 ? null : args[i + 1];
}
const report = JSON.parse(readFileSync(arg("report"), "utf8"));
const dispositionsPath = arg("dispositions");
const validationPath = arg("validation");
const mode = arg("mode") || "report-only";
const dispositions = dispositionsPath
  ? (() => {
      try {
        const raw = JSON.parse(readFileSync(dispositionsPath, "utf8"));
        return Array.isArray(raw) ? raw : (raw.entries ?? []);
      } catch {
        return [];
      }
    })()
  : [];
let validation = null;
if (validationPath) {
  try {
    validation = JSON.parse(readFileSync(validationPath, "utf8"));
  } catch {
    validation = null;
  }
}

const L = [];
L.push(`## Upstream sync: pstack ${report.base.short}..${report.head.short}`);
L.push("");
L.push(
  `Upstream [\`${report.head.short}\`](https://github.com/cursor/plugins/commit/${report.head.sha}) has **${report.commitCount} commits** touching \`${report.upstream.dir}/\` that are not integrated yet (tracked baseline: \`${report.base.short}\`, ${report.base.date}).`
);
L.push("");
if (mode === "report-only") {
  L.push("> ⚠️ **Report-only run.** No `ANTHROPIC_API_KEY`/`CLAUDE_CODE_OAUTH_TOKEN` secret is configured (or the dry-run flag was set), so changes were **not** adapted. Review the report below and port manually, or add credentials and re-run the workflow.");
  L.push("");
} else {
  L.push("> 🤖 Changes below were adapted with Claude per `AGENTS.md`. Nothing merges automatically; the tracked SHA advances only when this PR merges.");
  L.push("");
}

// --- upstream commits detected ---
L.push("### Upstream commits detected");
L.push("");
L.push("| Commit | Date | Subject |");
L.push("|---|---|---|");
for (const c of report.commits) {
  L.push(`| [\`${c.short}\`](https://github.com/cursor/plugins/commit/${c.sha}) | ${c.date} | ${c.subject.replace(/\|/g, "\\|")} |`);
}
L.push("");

// --- incorporated / manual / excluded ---
const ported = dispositions.filter((d) => d.disposition === "ported");
const notApplicable = dispositions.filter((d) => d.disposition === "not-applicable");
const manual = dispositions.filter((d) => d.disposition === "manual");
const excluded = report.changes.filter((c) => c.action === "exclude");
const review = report.changes.filter((c) => c.action === "review");

L.push("### Changes incorporated");
L.push("");
if (mode === "adapted" && ported.length) {
  for (const d of ported) {
    const ch = report.changes.find((c) => c.upstreamPath === d.upstreamPath);
    const to = ch ? ` → \`${ch.portPath}\`` : "";
    L.push(`- \`${d.upstreamPath}\`${to}${d.note ? ` — ${d.note}` : ""}`);
  }
} else if (ported.length) {
  L.push(`_Adaptation not run; ${ported.length} changes were classified as portable._`);
} else {
  L.push(mode === "adapted" ? "_None beyond the tracked baseline._" : `_See the full change list below (${report.changeCount} files)._`);
}
L.push("");

if (notApplicable.length) {
  L.push("### Changes evaluated as not applicable");
  L.push("");
  for (const d of notApplicable) {
    L.push(`- \`${d.upstreamPath}\`${d.note ? ` — ${d.note}` : ""}`);
  }
  L.push("");
}

L.push("### Changes requiring manual intervention");
L.push("");
const manualEntries = manual.map((d) => `- \`${d.upstreamPath}\`${d.note ? ` — ${d.note}` : ""}`);
for (const c of review) manualEntries.push(`- \`${c.upstreamPath}\` — ${c.reason}`);
if (manualEntries.length) L.push(...manualEntries);
else L.push("_None detected._");
L.push("");

L.push("### Intentionally excluded");
L.push("");
const exclSeen = new Set();
for (const c of excluded) {
  if (exclSeen.has(c.reason)) continue;
  exclSeen.add(c.reason);
  L.push(`- \`${c.upstreamPath.split("/").slice(0, 2).join("/")}\` — ${c.reason}`);
}
L.push("");

// --- validation ---
L.push("### Validation");
L.push("");
if (validation) {
  L.push(
    `${validation.ok ? "✅ PASS" : "❌ FAIL"} — ${validation.errors.length} errors, ${validation.warnings.length} warnings over ${validation.changedFileCount} changed files.`
  );
  for (const e of validation.errors) L.push(`- ❌ ${e}`);
  for (const w of validation.warnings.slice(0, 20)) L.push(`- ⚠️ ${w}`);
  if (validation.scriptsTouched?.length) {
    L.push("");
    L.push(`**Scripts touched** (committed for review; never executed by the sync): ${validation.scriptsTouched.map((s) => `\`${s}\``).join(", ")}`);
  }
} else {
  L.push("_Validation not run (report-only mode)._");
}
L.push("");
L.push("---");
L.push("");
L.push(
  `Merging this PR advances \`.upstream-sync/state.json\` to \`${report.head.short}\`. Closing it without merging leaves the baseline at \`${report.base.short}\` and the next run regenerates the sync.`
);
process.stdout.write(L.join("\n") + "\n");
