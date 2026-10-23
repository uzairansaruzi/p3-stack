// Validate the repo and/or an in-progress upstream sync.
//
// Usage:
//   node scripts/upstream/validate.mjs [--base <ref>] [--report <detect.json>]
//        [--dispositions <dispositions.json>] [--expect-state-advance <sha>]
//        [--out <result.json>] [--full]
//
// Exit codes: 0 = pass (warnings allowed), 1 = validation errors.
// --full also applies forbidden-term checks to the whole tree; errors there
// are reported as warnings so pre-existing issues never block a sync, but
// the report makes them visible.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, relative, isAbsolute } from "node:path";
import {
  REPO_ROOT,
  git,
  parseFrontmatter,
  forbiddenMatches,
  FORBIDDEN_FRONTMATTER_KEYS,
  ALLOWED_FRONTMATTER_KEYS,
  toPosix,
} from "./lib.mjs";

const args = process.argv.slice(2);
function arg(name, fallback = null) {
  const i = args.indexOf(`--${name}`);
  return i === -1 ? fallback : args[i + 1];
}
const BASE = arg("base", "origin/main");
const REPORT = arg("report");
const DISPOSITIONS = arg("dispositions");
const EXPECT_STATE = arg("expect-state-advance");
const OUT = arg("out");
const FULL = args.includes("--full");

const errors = [];
const warnings = [];
const notes = [];

function relRepo(p) {
  return toPosix(relative(REPO_ROOT, p));
}

// Intent-to-add so untracked new files appear in diffs against BASE.
git(["add", "-A", "-N", "."]);

const changed = git(["diff", "--name-only", "-M", BASE])
  .split("\n")
  .filter(Boolean);
const changedStatus = git(["diff", "--name-status", "-M", BASE])
  .split("\n")
  .filter(Boolean)
  .map((l) => {
    const parts = l.split("\t");
    if (parts[0].startsWith("R") || parts[0].startsWith("C")) {
      return { status: parts[0][0], from: parts[1], to: parts[2] };
    }
    return { status: parts[0][0], from: parts[1], to: parts[1] };
  });
const deleted = changedStatus.filter((c) => c.status === "D").map((c) => c.from);
const added = changedStatus.filter((c) => c.status === "A" || c.status === "C").map((c) => c.to);

// ---------------------------------------------------------------------------
// 1. Frontmatter: every skills/**/SKILL.md (whole tree — cheap and stable).
// ---------------------------------------------------------------------------
function listSkillFiles() {
  return git(["ls-files", "skills/*/SKILL.md", "skills/*/**/SKILL.md"])
    .split("\n")
    .filter(Boolean);
}

for (const file of listSkillFiles()) {
  const text = readFileSync(join(REPO_ROOT, file), "utf8");
  const fm = parseFrontmatter(text);
  const skillName = file.split("/")[1];
  if (!fm.ok) {
    errors.push(`frontmatter: ${file}: ${fm.error}`);
    continue;
  }
  if (fm.data.name !== skillName) {
    errors.push(`frontmatter: ${file}: name "${fm.data.name}" != directory "${skillName}"`);
  }
  if (!fm.data.description || String(fm.data.description).trim() === "") {
    errors.push(`frontmatter: ${file}: missing description`);
  }
  if (String(fm.data.description ?? "").includes("\n")) {
    errors.push(`frontmatter: ${file}: description must be one line`);
  }
  for (const key of FORBIDDEN_FRONTMATTER_KEYS) {
    if (key in fm.data) errors.push(`frontmatter: ${file}: Cursor UI field "${key}" must be dropped`);
  }
  for (const key of Object.keys(fm.data)) {
    if (!ALLOWED_FRONTMATTER_KEYS.includes(key)) {
      warnings.push(`frontmatter: ${file}: unknown field "${key}" (allowed: ${ALLOWED_FRONTMATTER_KEYS.join(", ")})`);
    }
  }
}

// ---------------------------------------------------------------------------
// 2. Forbidden terms (AGENTS.md definition of done).
//    Errors on files changed since BASE; --full adds whole-tree warnings.
// ---------------------------------------------------------------------------
function checkForbidden(files, onError, onWarn) {
  for (const file of files) {
    if (!/^(skills|agents)\//.test(file)) continue;
    if (!existsSync(join(REPO_ROOT, file))) continue; // deleted
    const text = readFileSync(join(REPO_ROOT, file), "utf8");
    for (const hit of forbiddenMatches(text)) {
      (onError ? onError : onWarn)?.(file, hit);
    }
  }
}
checkForbidden(
  changed,
  (file, hit) => errors.push(`forbidden: ${file}:${hit.line} ${hit.label}: ${hit.text}`),
  null
);
if (FULL) {
  const all = git(["ls-files", "skills/", "agents/"]).split("\n").filter(Boolean);
  checkForbidden(
    all.filter((f) => !changed.includes(f)),
    null,
    (file, hit) => warnings.push(`forbidden (pre-existing): ${file}:${hit.line} ${hit.label}`)
  );
}

// ---------------------------------------------------------------------------
// 3. T3 tool vocabulary: never invent T3 tool APIs.
// ---------------------------------------------------------------------------
const KNOWN_T3_TOOLS = new Set(
  (
    "delegate_task task_status task_cancel orchestrator_capabilities " +
    "t3_thread_launch t3_thread_list t3_thread_read t3_thread_search t3_thread_send " +
    "t3_thread_wait t3_thread_fork t3_thread_merge_back t3_thread_interrupt " +
    "t3_thread_organize t3_thread_update t3_thread_configure create_threads " +
    "t3_worktree_status t3_worktree_list t3_worktree_handoff " +
    "link_pull_request list_thread_pull_requests watch_pull_request unwatch_pull_request unlink_pull_request " +
    "schedule_task list_scheduled_tasks update_scheduled_task delete_scheduled_task run_scheduled_task_now " +
    "t3_queue_list t3_queue_read t3_queue_edit t3_queue_reorder t3_queue_cancel t3_queue_promote_to_steer " +
    "preview_open preview_navigate preview_snapshot preview_click preview_type preview_press preview_scroll " +
    "preview_wait_for preview_status preview_resize preview_set_appearance preview_recording_start " +
    "preview_recording_stop preview_hover preview_drag preview_select preview_dialog preview_upload " +
    "preview_evaluate t3_preview_list t3_preview_close " +
    "device_list device_open device_screenshot device_close " +
    "t3_pending_request_list t3_pending_request_read t3_pending_request_respond request_secret " +
    "t3_attachment_prepare_upload t3_attachment_discard t3_thread_send_attachments " +
    "t3_environment_read t3_environment_preferences_update t3_project_list t3_project_read t3_project_clone t3_project_create t3_project_update t3_project_delete"
  ).split(/\s+/)
);
const T3_CANDIDATE = /\b((?:t3|preview|device)_[a-z0-9_]+|[a-z]+_task\b|[a-z]+_pull_request\b|task_status|task_cancel|delegate_task|orchestrator_capabilities|create_threads|request_secret)\b/g;

for (const file of changed) {
  if (!/^(skills|agents)\//.test(file) || !file.endsWith(".md")) continue;
  if (!existsSync(join(REPO_ROOT, file))) continue;
  const text = readFileSync(join(REPO_ROOT, file), "utf8");
  const seen = new Set();
  for (const m of text.matchAll(T3_CANDIDATE)) {
    const token = m[1];
    if (seen.has(token)) continue;
    seen.add(token);
    if (!KNOWN_T3_TOOLS.has(token)) {
      errors.push(`t3-vocabulary: ${file}: "${token}" is not a known T3 tool (see AGENTS.md quick reference)`);
    }
  }
}

// ---------------------------------------------------------------------------
// 4. Reference resolution inside changed skill markdown.
// ---------------------------------------------------------------------------
for (const file of changed) {
  if (!/^skills\//.test(file) || !file.endsWith(".md")) continue;
  if (!existsSync(join(REPO_ROOT, file))) continue;
  const text = readFileSync(join(REPO_ROOT, file), "utf8");
  const dir = dirname(file);
  const linkRe = /\]\(([^)#\s]+?)(?:#[^)\s]*)?\)/g;
  for (const m of text.matchAll(linkRe)) {
    const target = m[1];
    if (/^(https?:|mailto:|\/)/.test(target)) continue;
    const abs = join(REPO_ROOT, dir, target);
    if (!existsSync(abs)) {
      errors.push(`reference: ${file}: link target "${target}" does not exist`);
    }
  }
  const backtickRe = /`((?:\.\.?\/|playbooks\/|references\/|scripts\/|sources\/)[A-Za-z0-9._\-\/]+\.(?:md|mjs|sh|ts|json|tsv|cfg))`/g;
  for (const m of text.matchAll(backtickRe)) {
    const target = m[1];
    const abs = join(REPO_ROOT, dir, target);
    if (!existsSync(abs)) {
      errors.push(`reference: ${file}: backtick path "${target}" does not exist`);
    }
  }
  for (const m of text.matchAll(/\b(principle-[a-z][a-z-]+)\b/g)) {
    const slug = m[1].replace(/-+$/, "");
    if (!existsSync(join(REPO_ROOT, "skills", slug, "SKILL.md"))) {
      errors.push(`reference: ${file}: principle "${slug}" has no skills/${slug}/SKILL.md`);
    }
  }
}

// ---------------------------------------------------------------------------
// 5. Core-file protection and deletion guard.
//    Scoped to adaptation runs (--dispositions): the guard exists to keep an
//    automated adaptation from overwriting T3-specific core; human PRs may
//    change these files on purpose.
// ---------------------------------------------------------------------------
const PROTECTED = ["AGENTS.md", "install.sh", ".github/", "scripts/upstream/", ".upstream-sync/config.json"];
if (DISPOSITIONS) {
  for (const c of changedStatus) {
    for (const p of PROTECTED) {
      if (c.to === p || c.to.startsWith(p) || c.from === p || c.from.startsWith(p)) {
        errors.push(`protected: sync must not modify "${c.to}" (T3-specific core; change it in a normal PR)`);
      }
    }
  }
}
if (REPORT) {
  const report = JSON.parse(readFileSync(REPORT, "utf8"));
  const upstreamDeletedOrMoved = new Set(
    report.changes
      .filter((c) => c.status === "D" || c.status === "R")
      .flatMap((c) => [c.portOldPath || c.portPath, c.portPath].filter(Boolean))
  );
  for (const file of deleted) {
    if (upstreamDeletedOrMoved.has(file)) continue;
    errors.push(`deletion: "${file}" deleted locally without a matching upstream deletion/rename`);
  }
}

// ---------------------------------------------------------------------------
// 6. Disposition completeness (adapted sync only).
// ---------------------------------------------------------------------------
let dispositions = null;
if (DISPOSITIONS) {
  const raw = JSON.parse(readFileSync(DISPOSITIONS, "utf8"));
  const entries = Array.isArray(raw) ? raw : raw.entries;
  if (!Array.isArray(entries)) {
    errors.push("dispositions: expected an array (or {entries: [...]})");
  } else {
    dispositions = entries;
    const valid = new Set(["ported", "not-applicable", "manual"]);
    const seen = new Set();
    for (const e of entries) {
      if (!e.upstreamPath || !valid.has(e.disposition)) {
        errors.push(`dispositions: bad entry ${JSON.stringify(e).slice(0, 120)}`);
        continue;
      }
      seen.add(e.upstreamPath);
      if (e.disposition === "ported" && !e.note) {
        warnings.push(`dispositions: ${e.upstreamPath} ported without a note`);
      }
    }
    if (REPORT) {
      const report = JSON.parse(readFileSync(REPORT, "utf8"));
      const needsDisposition = report.changes.filter(
        (c) => c.action === "port" || c.action === "scripts"
      );
      for (const c of needsDisposition) {
        if (!seen.has(c.upstreamPath)) {
          errors.push(`dispositions: upstream change "${c.upstreamPath}" (${c.action}) has no disposition`);
        }
      }
      // Ported entries must correspond to a changed port file.
      const changedSet = new Set(changed);
      for (const e of entries) {
        if (e.disposition !== "ported") continue;
        const match = report.changes.find((c) => c.upstreamPath === e.upstreamPath);
        if (!match) continue;
        if (!changedSet.has(match.portPath)) {
          errors.push(
            `dispositions: "${e.upstreamPath}" marked ported but "${match.portPath}" is unchanged`
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 7. State coherence after an advance.
// ---------------------------------------------------------------------------
if (EXPECT_STATE) {
  const state = JSON.parse(readFileSync(join(REPO_ROOT, ".upstream-sync", "state.json"), "utf8"));
  if (state.last_integrated_sha !== EXPECT_STATE) {
    errors.push(
      `state: last_integrated_sha ${state.last_integrated_sha} != expected ${EXPECT_STATE}`
    );
  }
  if (!Array.isArray(state.history) || !state.history.some((h) => h.sha === EXPECT_STATE)) {
    errors.push(`state: history has no entry for ${EXPECT_STATE}`);
  }
}

// ---------------------------------------------------------------------------
// 8. Script disclosure (never executed by the sync; listed for review).
// ---------------------------------------------------------------------------
const scriptsTouched = changed.filter(
  (f) => /\.(mjs|js|ts|sh|py)$/.test(f) || /\/scripts\//.test(f)
);
if (scriptsTouched.length) {
  notes.push(`scripts touched (committed for review, never executed by sync): ${scriptsTouched.join(", ")}`);
}

// ---------------------------------------------------------------------------
const result = {
  ok: errors.length === 0,
  base: BASE,
  checkedAt: new Date().toISOString(),
  changedFileCount: changed.length,
  errors,
  warnings,
  notes,
  scriptsTouched,
};
if (OUT) writeFileSync(OUT, JSON.stringify(result, null, 2) + "\n");
for (const e of errors) console.error(`FAIL ${e}`);
for (const w of warnings) console.warn(`WARN ${w}`);
for (const n of notes) console.log(`NOTE ${n}`);
console.log(`${result.ok ? "PASS" : "FAIL"}: ${errors.length} errors, ${warnings.length} warnings, ${changed.length} changed files`);
process.exit(result.ok ? 0 : 1);
