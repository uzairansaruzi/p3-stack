// Advance .upstream-sync/state.json to a new upstream SHA.
// Called by the workflow ONLY after validation passes on an adapted sync.
// The advance lands on main only when the sync PR merges, so the tracked
// SHA never marks unreviewed changes as synchronized.
// Usage: node scripts/upstream/advance-state.mjs <sha> [--summary "<text>"]
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { git, REPO_ROOT } from "./lib.mjs";

const args = process.argv.slice(2);
const sha = args[0];
if (!/^[0-9a-f]{40}$/i.test(sha ?? "")) {
  console.error("usage: advance-state.mjs <full-sha> [--summary <text>]");
  process.exit(2);
}
const summaryIdx = args.indexOf("--summary");
const summary = summaryIdx === -1 ? null : args[summaryIdx + 1];

const statePath = join(REPO_ROOT, ".upstream-sync", "state.json");
const state = JSON.parse(readFileSync(statePath, "utf8"));
if (state.last_integrated_sha === sha) {
  console.log(`state already at ${sha.slice(0, 10)}`);
  process.exit(0);
}

const date = git(["show", "-s", "--format=%cs", sha]) || new Date().toISOString().slice(0, 10);
state.history.push({
  sha,
  date,
  previous: state.last_integrated_sha,
  advancedAt: new Date().toISOString(),
  summary: summary || null,
});
state.last_integrated_sha = sha;
state.last_integrated_date = date;
delete state.last_integrated_note;
state.updated_at = new Date().toISOString();

writeFileSync(statePath, JSON.stringify(state, null, 2) + "\n");
console.log(`state advanced to ${sha.slice(0, 10)}`);
