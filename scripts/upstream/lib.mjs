// Shared library for the p3-stack upstream sync tooling.
// Node built-ins only; no dependencies; never executes upstream code.
import { execFileSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { dirname, join, normalize, sep } from "node:path";
import { fileURLToPath } from "node:url";

export const REPO_ROOT = normalize(join(dirname(fileURLToPath(import.meta.url)), "..", ".."));

export function run(cmd, args, opts = {}) {
  return execFileSync(cmd, args, {
    cwd: opts.cwd || REPO_ROOT,
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
    stdio: opts.captureStderr === false ? ["ignore", "pipe", "ignore"] : "pipe",
  }).trimEnd();
}

export function git(args, opts = {}) {
  return run("git", args, opts);
}

export function loadState() {
  return JSON.parse(readFileSync(join(REPO_ROOT, ".upstream-sync", "state.json"), "utf8"));
}

export function loadConfig() {
  return JSON.parse(readFileSync(join(REPO_ROOT, ".upstream-sync", "config.json"), "utf8"));
}

// --- glob matching (supports **, *, and exact segments) ---

function globToRegExp(glob) {
  let re = "^";
  for (let i = 0; i < glob.length; i++) {
    const ch = glob[i];
    if (ch === "*") {
      if (glob[i + 1] === "*") {
        // `**` matches any number of path segments (including none);
        // a trailing `/**` also matches the directory itself.
        if (glob[i - 1] === "/" && glob[i + 2] === undefined) re += "(?:.*)?$";
        else re += "(?:[^/]*(?:/|$))*";
        i++;
      } else {
        re += "[^/]*";
      }
    } else if (ch === "?" || ch === "." || ch === "/") {
      re += ch === "/" ? "/" : ch === "." ? "\\." : "[^/]";
    } else {
      re += ch.replace(/[\\^$()+{}\[\]|]/g, "\\$&");
    }
  }
  return new RegExp(re.endsWith("$") ? re : re + "$");
}

function matchesGlob(path, glob) {
  return globToRegExp(glob).test(path);
}

// --- path mapping and classification ---

// Map an upstream path (relative to <upstream_dir>/) to its p3-stack path.
// Returns { path, renamed } or null when the path has no direct mapping
// (only happens for path_map keys that are exact files not present).
export function mapPath(upstreamRel, config) {
  for (const [from, to] of Object.entries(config.path_map)) {
    if (upstreamRel === from) return { path: to, renamed: true };
    if (upstreamRel.startsWith(from + "/")) {
      return { path: to + upstreamRel.slice(from.length), renamed: true };
    }
  }
  return { path: upstreamRel, renamed: false };
}

// Classify an upstream change into an action the sync can take.
// action: "port" (adapt via Claude), "scripts" (adapt, copy scripts verbatim,
// never execute), "exclude" (documented intentional exclusion),
// "review" (report for a manual decision).
export function classify(upstreamRel, config) {
  for (const rule of config.exclude) {
    if (matchesGlob(upstreamRel, rule.path)) {
      return { action: "exclude", reason: rule.reason };
    }
  }
  for (const rule of config.review || []) {
    if (matchesGlob(upstreamRel, rule.path)) {
      return { action: "review", reason: rule.reason };
    }
  }
  if (/^skills\/[^/]+\/scripts\//.test(upstreamRel)) return { action: "scripts" };
  if (/^skills\/.*\.md$/.test(upstreamRel) || /^agents\/.*\.md$/.test(upstreamRel)) {
    return { action: "port" };
  }
  // New skill support files (tsv, json, etc.) and anything under skills/ or agents/.
  if (/^(skills|agents)\//.test(upstreamRel)) return { action: "port" };
  // Unprecedented top-level additions: always a manual decision.
  return { action: "review", reason: "Unrecognized upstream path; needs a manual decision." };
}

// --- frontmatter (minimal YAML subset used by SKILL.md files) ---

export function parseFrontmatter(text) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(text);
  if (!m) return { ok: false, error: "missing --- frontmatter block", data: null, body: text };
  const data = {};
  for (const line of m[1].split(/\r?\n/)) {
    if (!line.trim() || line.trim().startsWith("#")) continue;
    const kv = /^([A-Za-z0-9_-]+):\s*(.*)$/.exec(line);
    if (!kv) return { ok: false, error: `unparseable frontmatter line: ${line.trim()}`, data: null, body: m[2] };
    const [, key, raw] = kv;
    let value = raw.trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    } else if (value === "true" || value === "false") {
      value = value === "true";
    }
    data[key] = value;
  }
  return { ok: true, error: null, data, body: m[2] };
}

// --- AGENTS.md "definition of done" checks ---

// Word-boundary patterns; "precursor"/"upstack" do not trigger these.
export const FORBIDDEN_PATTERNS = [
  [/\bcursor\b/i, "Cursor reference"],
  [/\bTask tool\b/, "Cursor Task tool"],
  [/\bsubagent_type\b/, "Cursor subagent_type"],
  [/\bcloud agent\b/i, "Cursor cloud agent"],
  [/cloud_base_branch/, "Cursor cloud_base_branch"],
  [/environment:\s*["']?cloud["']?/i, "Cursor cloud environment"],
  [/\.cursor\b/i, ".cursor path"],
  [/agent-transcripts/, "agent-transcripts mining"],
  [/\bAskQuestion\b/, "Cursor AskQuestion"],
  [/\b(claude|grok|gpt)-/i, "hardcoded model slug"],
  [/(?<![\w.\-])\/loop\b/, "Cursor /loop"],
  [/\bpoteto\b/i, "poteto naming (p3-stack uses p3-)"],
  [/\bpstack\b/i, "pstack naming (p3-stack uses p3-)"],
];

// Frontmatter keys Cursor uses but T3 skills must drop (AGENTS.md writing rules).
export const FORBIDDEN_FRONTMATTER_KEYS = ["icon", "color", "mode", "reminder"];
export const ALLOWED_FRONTMATTER_KEYS = ["name", "description", "disable-model-invocation"];

export function forbiddenMatches(text) {
  const hits = [];
  const lines = text.split(/\r?\n/);
  for (const [pattern, label] of FORBIDDEN_PATTERNS) {
    lines.forEach((line, i) => {
      pattern.lastIndex = 0;
      if (pattern.test(line)) hits.push({ line: i + 1, label, text: line.trim().slice(0, 120) });
    });
  }
  return hits;
}

// --- misc helpers ---

export function toPosix(p) {
  return p.split(sep).join("/");
}
