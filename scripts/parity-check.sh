#!/usr/bin/env bash
# parity-check.sh: check p3-stack against upstream pstack with the nine criteria of
# docs/sync-spec-c742dd6.md §4 (P1..P8) plus P9 (verbatim files and pin-version). Read-only; reads UPSTREAM.md.
#
# usage: scripts/parity-check.sh [--to <rev>] [--upstream <path|url>] [--no-fetch] [--all]
# prints one PASS / ALLOW / FAIL line per criterion (P4, P5, P8 judge each unit against its 对齐到 commit) (ALLOW = only whitelisted exceptions);
# whitelist rows that excused nothing are listed as STALE (reported, not a FAIL; delete them).
# --all lists every offending path instead of the first 12. exit 1 when any FAIL, 2 on error.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UP_MD="$ROOT/UPSTREAM.md"
TO="" UPSTREAM="" FETCH=1 ALL=0

die() { printf 'error: %s\n' "$*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) TO="${2:?--to needs a rev}"; shift 2 ;;
    --upstream) UPSTREAM="${2:?--upstream needs a path or url}"; shift 2 ;;
    --no-fetch) FETCH=0; shift ;;
    --all) ALL=1; shift ;;
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -f "$UP_MD" ]] || die "missing $UP_MD"
command -v node >/dev/null || die "node is required"

# shellcheck source=lib/upstream.sh
source "$ROOT/scripts/lib/upstream.sh"
up_open "$UPSTREAM" "$TO" "$FETCH"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
table "映射" > "$TMP/map.tsv"
table "白名单" > "$TMP/wl.tsv"
table "逐字搬运" > "$TMP/strict.tsv"

export ROOT UP SUBTREE TO_FULL PIN_FULL PIN_VERSION="$(header pin-version)" ALL MAPF="$TMP/map.tsv" WLF="$TMP/wl.tsv" STRICTF="$TMP/strict.tsv"
for n in "${NOTES[@]:-}"; do [[ -n "$n" ]] && printf 'note: %s\n' "$n"; done
printf 'parity: p3-stack vs upstream %s @ %s\n' "$SUBTREE" "$(S "$TO_FULL")"
node --input-type=module - <<'JS'
import { execFileSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'

const { ROOT, UP, SUBTREE, TO_FULL, PIN_FULL, PIN_VERSION } = process.env
const ALL = process.env.ALL === '1'
const git = (...a) => execFileSync('git', ['-C', UP, ...a], { encoding: 'utf8', maxBuffer: 1 << 28 })
const showAt = (rev, p) => { try { return git('show', `${rev}:${SUBTREE}/${p}`) } catch { return null } }
const show = (p) => showAt(TO_FULL, p)
const rows = (f) => fs.readFileSync(f, 'utf8').split('\n').filter(Boolean).map((l) => l.split('\t'))
const map = rows(process.env.MAPF).map(([up, p3, al, st]) => ({ up, p3, al, st }))
const wl = rows(process.env.WLF).map(([crit, p, why]) => ({ crit, p, why }))
const strict = rows(process.env.STRICTF).map(([g]) => g)
const re = (g) => new RegExp('^' + g.replace(/[.+^$(){}|\\]/g, '\\$&').replace(/\*\*/g, '\u0001').replace(/\*/g, '[^/]*').replace(/\u0001/g, '.*') + '$')
const wlRe = wl.map((w) => ({ ...w, re: re(w.p), used: false }))
const allowed = (label, ...ps) => {
  const hit = wlRe.filter((w) => (w.crit === label || w.crit === label.split(' ')[0]) && ps.some((p) => w.re.test(p)))
  hit.forEach((w) => { w.used = true })
  return hit.length > 0
}

// rename map derived from the mapping table (upstream name -> p3 name)
const renames = map.filter((r) => path.basename(r.up) !== path.basename(r.p3) && r.p3 !== '—')
  .map((r) => [path.basename(r.up).replace(/\.md$/, ''), path.basename(r.p3).replace(/\.md$/, '')])
const rename = (t) => renames.reduce((s, [a, b]) => s.split(a).join(b), t)
const norm = (l) => l.replace(/\s+/g, ' ').trim()

const toP3 = (up) => {
  const r = map.filter((m) => up === m.up || up.startsWith(m.up + '/')).sort((a, b) => b.up.length - a.up.length)[0]
  return r ? { row: r, p3: r.p3 === '—' ? null : r.p3 + up.slice(r.up.length) } : null
}
const toUp = (p3) => {
  const r = map.filter((m) => m.p3 !== '—' && (p3 === m.p3 || p3.startsWith(m.p3 + '/'))).sort((a, b) => b.p3.length - a.p3.length)[0]
  return r ? { row: r, up: r.up + p3.slice(r.p3.length) } : null
}
// P4/P5/P8 compare each file with the upstream version its unit is aligned to (row 对齐到), falling back to the target,
// so a half-synced tree is judged on what it claims to have synced. Verbatim files and P1-P3, P6, P7 always use the target.
const showAligned = (u) => {
  const al = toP3(u)?.row.al
  return al && al !== '—' ? showAt(git('rev-parse', `${al}^{commit}`).trim(), u) : show(u)
}
const upFiles = git('ls-tree', '-r', '--name-only', TO_FULL, SUBTREE + '/').split('\n').filter(Boolean)
  .map((p) => p.slice(SUBTREE.length + 1))
const inScope = (p) => /^(skills|agents)\//.test(p) && !p.includes('/scripts/')
const upScoped = upFiles.filter(inScope)
const walk = (d) => fs.existsSync(d) ? fs.readdirSync(d, { withFileTypes: true }).flatMap((e) =>
  e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]) : []
const p3Files = ['skills', 'agents'].flatMap((d) => walk(path.join(ROOT, d))).map((f) => path.relative(ROOT, f)).sort()
const p3Scoped = p3Files.filter(inScope)
const p3Set = new Set(p3Files)
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8')

const results = []
const crit = (id, label) => { const c = { id, label, fails: [], allows: [], info: [] }; results.push(c); return c }
const check = (c, ok, path_, msg, ...alt) => {
  if (ok) return
  if (allowed(c.id, path_, ...alt)) c.allows.push(`${path_}: ${msg}`)
  else c.fails.push(`${path_}: ${msg}`)
}

// P1 every upstream skill has a p3 skill
{
  const c = crit('P1', 'upstream skills have a p3 skill')
  const ups = [...new Set(upFiles.filter((p) => p.startsWith('skills/')).map((p) => p.split('/')[1]))]
  c.info.push(`${ups.length} upstream skills, ${fs.readdirSync(path.join(ROOT, 'skills')).length} p3 skills`)
  for (const s of ups) {
    const r = map.find((m) => m.up === `skills/${s}`)
    if (!r) { c.fails.push(`skills/${s}: not registered in UPSTREAM.md`); continue }
    if (r.st === 'gap') { c.allows.push(`skills/${s}: gap`); continue }
    check(c, fs.existsSync(path.join(ROOT, r.p3, 'SKILL.md')), r.p3, `missing (status ${r.st})`, `skills/${s}`)
  }
}
// P2 file-level correspondence both ways
{
  const c = crit('P2', 'files correspond both ways (skills/, agents/, excluding scripts/)')
  const upSet = new Set(upScoped)
  for (const u of upScoped) {
    const m = toP3(u)
    if (!m) { c.fails.push(`${u}: no mapping row`); continue }
    if (m.row.st === 'gap') { c.allows.push(`${u}: gap`); continue }
    check(c, m.p3 && p3Set.has(m.p3), m.p3 ?? u, `missing in p3 (upstream ${u})`, u)
  }
  for (const f of p3Scoped) {
    const m = toUp(f)
    if (m?.row.st === 'p3-only') continue
    check(c, m && upSet.has(m.up), f, 'extra in p3, no upstream counterpart')
  }
  c.info.push(`${upScoped.length} upstream files, ${p3Scoped.length} p3 files`)
}
// P3 Cursor residue words
{
  const c = crit('P3', 'no Cursor residue words (AGENTS.md definition of done 1)')
  const pat = 'Cursor|Task tool|subagent_type|cloud agent|\\.cursor|agent-transcripts|AskQuestion|icon:|claude-|grok-|gpt-|/loop'
  const run = (...args) => { if (!args.length) return ''; try { return execFileSync('grep', ['-rEn', pat, ...args], { cwd: ROOT, encoding: 'utf8' }) } catch (e) { return e.status === 1 ? '' : (() => { throw e })() } }
  const out = run('skills', 'agents', '--exclude-dir=statechart') + run(...['skills/statechart/SKILL.md', 'skills/statechart/references'].filter((p) => fs.existsSync(path.join(ROOT, p))))
  for (const l of out.split('\n').filter(Boolean)) { const f = l.split(':')[0]; check(c, false, f, l.slice(f.length + 1).slice(0, 110)) }
}
// P4 T3-native mechanisms
{
  const classes = [
    ['delegate', /\bTask\b|subagent_type|run_in_background/, /delegate_task|t3_thread_launch/],
    ['watch', /watch-pr|watcher/, /watch_pull_request/],
    ['schedule', /\/loop\b|hourly audit|hourly tick/, /schedule_task|watch_pull_request/],
    ['preview', /control-ui|control-cli/, /preview_|device_/],
    ['history', /agent-transcripts/, /t3_thread_read|t3_thread_search/],
  ]
  for (const [name, upRe, p3Re] of classes) {
    const c = crit(`P4 ${name}`, `upstream ${name} steps use T3 tools`)
    let total = 0
    for (const u of upScoped) {
      const m = toP3(u)
      if (!m?.p3 || !p3Set.has(m.p3) || !upRe.test(show(u) ?? '')) continue
      total++
      check(c, p3Re.test(read(m.p3)), m.p3, `upstream ${u} matches ${upRe}, p3 has none of ${p3Re}`, u)
    }
    c.info.push(`${total - c.fails.length - c.allows.length}/${total} files use T3 tools`)
  }
}
// P5 keep upstream sentences
{
  const c = crit('P5', 'upstream lines (>=30 chars) kept in p3')
  const stats = []
  for (const u of upScoped) {
    const m = toP3(u)
    if (!m?.p3 || !p3Set.has(m.p3) || !/\.md$/.test(u)) continue
    const strictFile = strict.some((g) => re(g).test(m.p3))
    const lines = rename((strictFile ? show(u) : showAligned(u)) ?? '').split('\n').map(norm).filter((l) => l.length >= 30)
    if (!lines.length) continue
    const mine = new Set(read(m.p3).split('\n').map(norm))
    const ratio = lines.filter((l) => mine.has(l)).length / lines.length
    stats.push([m.p3, ratio])
    check(c, strictFile ? ratio === 1 : ratio >= 0.4, m.p3, `${(ratio * 100).toFixed(0)}% kept, need ${strictFile ? '100% (verbatim)' : '>=40%'}`, u)
  }
  c.info.push(`${stats.filter((s) => s[1] === 1).length}/${stats.length} files at 100%, ${stats.filter((s) => s[1] < 0.5).length} below 50%`)
}
// P6 references resolve, names match, disable-model-invocation agrees
{
  const c = crit('P6', 'links resolve, name == dir, disable-model-invocation matches upstream')
  const fm = (t, k) => { const m = /^---\n([\s\S]*?)\n---/.exec(t ?? ''); const l = m && m[1].split('\n').find((x) => x.startsWith(k + ':')); return l ? l.slice(k.length + 1).trim() : null }
  for (const f of p3Files.filter((p) => p.endsWith('.md'))) {
    for (const mm of read(f).matchAll(/\]\(([^)\s]+)\)/g)) {
      const t = mm[1].split('#')[0]
      if (!t || /^[a-z]+:/.test(t) || t.startsWith('/') || !/[./]/.test(t)) continue
      check(c, fs.existsSync(path.join(ROOT, path.dirname(f), t)), f, `broken link ${t}`)
    }
    if (path.basename(f) === 'SKILL.md') {
      const dir = path.basename(path.dirname(f))
      check(c, fm(read(f), 'name') === dir, f, `name ${fm(read(f), 'name')} != dir ${dir}`)
      const m = toUp(f)
      if (m && m.row.st !== 'p3-only' && upFiles.includes(m.up)) {
        const a = fm(read(f), 'disable-model-invocation'), b = fm(show(m.up), 'disable-model-invocation')
        check(c, a === b, f, `disable-model-invocation p3=${a} upstream=${b}`)
      }
    }
  }
}
// P7 role names close between AGENTS.md and setup-p3, no slugs
{
  const c = crit('P7', 'role names close between AGENTS.md and setup-p3')
  const agents = read('AGENTS.md')
  const sec = agents.slice(agents.indexOf('## Role names'), agents.indexOf('## Writing rules'))
  const roleA = new Set([...sec.matchAll(/`([^`]+)`/g)].map((m) => m[1]).filter((x) => /^[a-z][a-z ,-]*$/.test(x)))
  const setup = fs.existsSync(path.join(ROOT, 'skills/setup-p3/SKILL.md')) ? read('skills/setup-p3/SKILL.md') : ''
  const block = /```\n(# p3 model[\s\S]*?)```/.exec(setup)?.[1] ?? ''
  const roleS = new Set(block.split('\n').filter((l) => !l.startsWith('#') && /^[a-z][a-z ,-]*: /.test(l)).map((l) => l.split(': ')[0]))
  for (const r of roleA) check(c, roleS.has(r), 'AGENTS.md', `role "${r}" missing from setup-p3 table`)
  for (const r of roleS) check(c, roleA.has(r), 'skills/setup-p3/SKILL.md', `role "${r}" missing from AGENTS.md`)
  c.info.push(`${roleA.size} roles in AGENTS.md, ${roleS.size} in setup-p3 (model slugs are covered by P3)`)
}
// P8 length does not regress
{
  const c = crit('P8', 'p3 files are not longer than upstream')
  const lines = (t) => t.split('\n').length - (t.endsWith('\n') ? 1 : 0)
  for (const u of upScoped) {
    const m = toP3(u)
    if (!m?.p3 || !p3Set.has(m.p3)) continue
    const a = lines(read(m.p3)), b = lines(showAligned(u) ?? '')
    check(c, a <= b, m.p3, `${a} lines vs upstream ${b}`, u)
  }
}
// P9 verbatim files are byte-identical to upstream; pin-version matches the pin
{
  const c = crit('P9', 'verbatim files byte-identical to upstream; pin-version matches the pin')
  const raw = (rev, p) => { try { return execFileSync('git', ['-C', UP, 'show', `${rev}:${SUBTREE}/${p}`], { maxBuffer: 1 << 28 }) } catch { return null } }
  const strictRe = strict.map(re)
  const isStrict = (p3) => strictRe.some((r) => r.test(p3))
  const p3All = ['skills', 'agents'].flatMap((d) => walk(path.join(ROOT, d))).map((f) => path.relative(ROOT, f))
  for (const g of strict) if (!p3All.some((f) => re(g).test(f))) c.fails.push(`${g}: matches no p3 file`)
  let n = 0
  const seen = new Set()
  for (const f of p3All.filter(isStrict)) {
    const m = toUp(f)
    if (!m) { c.fails.push(`${f}: verbatim but no mapping row`); continue }
    seen.add(f); n++
    const up = raw(TO_FULL, m.up)
    if (!up) { c.fails.push(`${f}: no upstream counterpart ${m.up}`); continue }
    check(c, up.equals(fs.readFileSync(path.join(ROOT, f))), f, `differs from upstream ${m.up}`)
  }
  for (const u of upFiles) {
    const m = toP3(u)
    if (m?.p3 && isStrict(m.p3) && !seen.has(m.p3)) c.fails.push(`${m.p3}: verbatim but missing (upstream ${u})`)
  }
  let upVersion = null
  try { upVersion = JSON.parse(execFileSync('git', ['-C', UP, 'show', `${PIN_FULL}:${SUBTREE}/.cursor-plugin/plugin.json`], { encoding: 'utf8' })).version } catch {}
  if (!PIN_VERSION) c.fails.push('UPSTREAM.md: pin-version missing')
  else if (!upVersion) c.fails.push(`upstream plugin.json unreadable at pin ${PIN_FULL.slice(0, 7)}`)
  else if (PIN_VERSION !== upVersion) c.fails.push(`UPSTREAM.md: pin-version ${PIN_VERSION} != upstream ${upVersion} at pin`)
  c.info.push(`${n} verbatim files, pin-version ${PIN_VERSION}`)
}

let fail = 0, allow = 0, pass = 0
for (const c of results) {
  const status = c.fails.length ? 'FAIL' : c.allows.length ? 'ALLOW' : 'PASS'
  if (status === 'FAIL') fail++; else if (status === 'ALLOW') allow++; else pass++
  console.log(`${status.padEnd(5)} ${c.id.padEnd(11)} ${c.label}${c.info.length ? '  [' + c.info.join('; ') + ']' : ''}${c.allows.length ? `  (${c.allows.length} whitelisted)` : ''}`)
  const show_ = ALL ? c.fails : c.fails.slice(0, 12)
  for (const f of show_) console.log(`        ${f}`)
  if (!ALL && c.fails.length > 12) console.log(`        ... ${c.fails.length - 12} more (use --all)`)
}
const stale = wlRe.filter((w) => !w.used)
for (const w of stale) console.log(`STALE ${w.crit} ${w.p}: whitelist row excused nothing`)
console.log(`total: PASS=${pass} ALLOW=${allow} FAIL=${fail} STALE=${stale.length}`)
process.exit(fail ? 1 : 0)
JS
