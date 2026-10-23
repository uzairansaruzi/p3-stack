// Detect upstream pstack changes since the last integrated SHA.
// Reads text via git only; never checks out or executes upstream code.
// Usage: node scripts/upstream/detect.mjs [--write] [--upstream-ref <ref>]
//   --write        persist .upstream-sync/reports/detect-<shortsha>.json
//   --upstream-ref override the resolved upstream head (testing only)
import { writeFileSync, mkdirSync, appendFileSync } from "node:fs";
import { join } from "node:path";
import { git, loadState, loadConfig, mapPath, classify, REPO_ROOT } from "./lib.mjs";

const args = process.argv.slice(2);
const write = args.includes("--write");
const refOverrideIdx = args.indexOf("--upstream-ref");
const refOverride = refOverrideIdx === -1 ? null : args[refOverrideIdx + 1];

const state = loadState();
const config = loadConfig();
const REMOTE = "upstream-sync-remote";
const dir = state.upstream_dir;

if (!git(["remote"]).split("\n").filter(Boolean).includes(REMOTE)) {
  git(["remote", "add", REMOTE, state.upstream_repo]);
}
git(["fetch", REMOTE, state.upstream_branch, "--no-tags"]);

const head = refOverride ?? git(["rev-parse", `${REMOTE}/${state.upstream_branch}`]);
const base = state.last_integrated_sha;
const shortHead = head.slice(0, 10);

// Ancestry sanity: upstream history rewrites are a manual event.
let ancestry = "ok";
try {
  git(["merge-base", "--is-ancestor", base, head]);
} catch {
  ancestry = "rewritten";
}

const commits =
  ancestry === "ok"
    ? git(["log", "--format=%H%x1f%h%x1f%cs%x1f%s", `${base}..${head}`, "--", `${dir}/`])
        .split("\n")
        .filter(Boolean)
        .map((line) => {
          const [sha, short, date, subject] = line.split("\x1f");
          return { sha, short, date, subject };
        })
    : [];

// name-status diff with rename detection, restricted to the pstack directory.
const diffLines =
  ancestry === "ok"
    ? git(["diff", "--name-status", "-M", base, head, "--", `${dir}/`]).split("\n").filter(Boolean)
    : [];

const changes = diffLines.map((line) => {
  const parts = line.split("\t");
  const status = parts[0];
  let upstreamPath,
    upstreamOldPath = null,
    similarity = null;
  if (status.startsWith("R") || status.startsWith("C")) {
    similarity = parseInt(status.slice(1) || "0", 10);
    [upstreamOldPath, upstreamPath] = parts.slice(1);
  } else {
    upstreamPath = parts[1];
  }
  const rel = upstreamPath.slice(dir.length + 1);
  const oldRel = upstreamOldPath ? upstreamOldPath.slice(dir.length + 1) : null;
  const mapped = mapPath(rel, config);
  const cls = classify(rel, config);
  const oldMapped = oldRel ? mapPath(oldRel, config) : null;
  return {
    status: status[0], // A, M, D, R, C
    similarity,
    upstreamPath: rel,
    upstreamOldPath: oldRel,
    portPath: mapped.path,
    portOldPath: oldMapped ? oldMapped.path : null,
    renamedInPort: mapped.renamed,
    action: cls.action, // port | scripts | exclude | review
    reason: cls.reason || null,
  };
});

const byAction = {};
for (const c of changes) byAction[c.action] = (byAction[c.action] || 0) + 1;

const report = {
  status:
    ancestry !== "ok"
      ? "upstream-history-rewritten"
      : commits.length === 0
        ? "up-to-date"
        : "changes-detected",
  generatedAt: new Date().toISOString(),
  upstream: { repo: state.upstream_repo, branch: state.upstream_branch, dir },
  base: { sha: base, short: base.slice(0, 10), date: state.last_integrated_date },
  head: { sha: head, short: shortHead },
  branch: `sync/upstream-${shortHead}`,
  commitCount: commits.length,
  commits,
  changeCount: changes.length,
  changesByAction: byAction,
  changes,
};

if (write) {
  mkdirSync(join(REPO_ROOT, ".upstream-sync", "reports"), { recursive: true });
  const out = join(REPO_ROOT, ".upstream-sync", "reports", `detect-${shortHead}.json`);
  writeFileSync(out, JSON.stringify(report, null, 2) + "\n");
  process.stdout.write(`report=${out}\n`);
}

const fields = {
  status: report.status,
  head_sha: head,
  head_short: shortHead,
  base_short: base.slice(0, 10),
  branch: report.branch,
  commits: String(commits.length),
  changes: String(changes.length),
};
for (const [k, v] of Object.entries(fields)) {
  process.stdout.write(`${k}=${v}\n`);
  if (process.env.GITHUB_OUTPUT) appendFileSync(process.env.GITHUB_OUTPUT, `${k}=${v}\n`);
}
