#!/usr/bin/env bash
# Tests install.sh against a temporary HOME. Never touches the real one.
# usage: scripts/install.test.sh
set -uo pipefail

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALL="$ROOT/install.sh"
SKILL_COUNT="$(ls "$ROOT/skills" | wc -l | tr -d ' ')"

PASS=0
FAIL=0
TMPDIRS=()
cleanup() {
  local d
  for d in ${TMPDIRS[@]+"${TMPDIRS[@]}"}; do rm -rf "$d"; done
}
trap cleanup EXIT

tmp() {
  local d
  d="$(mktemp -d)"
  TMPDIRS+=("$d")
  printf '%s\n' "$d"
}

ok() { PASS=$((PASS + 1)); printf 'ok %d - %s\n' "$((PASS + FAIL))" "$1"; }
no() {
  FAIL=$((FAIL + 1))
  printf 'not ok %d - %s\n' "$((PASS + FAIL))" "$1"
  [ $# -lt 2 ] || printf '  # %s\n' "$2"
}

# run <home> [args...]: run the installer against a temporary HOME
run() {
  local h="$1"
  shift
  env -u CLAUDE_CONFIG_DIR -u CODEX_HOME HOME="$h" "$INSTALL" "$@"
}

assert_link() { # label path expected
  if [ -L "$2" ] && [ "$(readlink "$2")" = "$3" ]; then
    ok "$1"
  else
    no "$1" "$2 -> $(readlink "$2" 2>/dev/null || printf 'missing')"
  fi
}

assert_absent() { # label path
  if [ -e "$2" ] || [ -L "$2" ]; then no "$1" "$2 exists"; else ok "$1"; fi
}

assert_count() { # label dir expected
  local n
  n="$(ls -A "$2" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$n" = "$3" ]; then ok "$1"; else no "$1" "$2 holds $n entries, want $3"; fi
}

has() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

assert_has() { # label text needle
  if has "$2" "$3"; then ok "$1"; else no "$1" "output lacks: $3"; fi
}

snapshot() { # dir: every entry with its link target
  (cd "$1" && find . ! -path . | LC_ALL=C sort | while IFS= read -r p; do
    if [ -L "$p" ]; then printf '%s -> %s\n' "$p" "$(readlink "$p")"; else printf '%s\n' "$p"; fi
  done)
}

# --- first install reaches every existing user-level target ------------------

H="$(tmp)"
mkdir -p "$H/.tclaude" "$H/.claude"
out="$(run "$H")"
rc=$?
[ "$rc" = 0 ] && ok "first install exits 0" || no "first install exits 0" "exit $rc"
assert_has "first install names ~/.agents/skills" "$out" "~/.agents/skills"
assert_has "first install names ~/.tclaude/skills" "$out" "~/.tclaude/skills"
assert_has "first install names ~/.claude/skills" "$out" "~/.claude/skills"
assert_count "~/.agents/skills holds every skill" "$H/.agents/skills" "$SKILL_COUNT"
assert_count "~/.tclaude/skills holds every skill" "$H/.tclaude/skills" "$SKILL_COUNT"
assert_count "~/.claude/skills holds every skill" "$H/.claude/skills" "$SKILL_COUNT"
assert_link "linked skill points into the repo" "$H/.agents/skills/tdd" "$ROOT/skills/tdd"
assert_link "claude target links the same skill" "$H/.claude/skills/tdd" "$ROOT/skills/tdd"
assert_absent "no agents link inside a config home" "$H/.claude/agents"
assert_absent "no agents link beside ~/.agents/skills" "$H/.agents/agents"

# --- a foreign symlink is skipped and left alone ------------------------------

H="$(tmp)"
E="$(tmp)"
mkdir -p "$H/.tclaude/skills" "$E/skills/tdd"
ln -s "$E/skills/tdd" "$H/.tclaude/skills/tdd"
out="$(run "$H")"
assert_has "foreign name is reported as skipped" "$out" "skip tdd: foreign symlink"
assert_link "foreign symlink keeps its target" "$H/.tclaude/skills/tdd" "$E/skills/tdd"
assert_count "other skills still link beside it" "$H/.tclaude/skills" "$SKILL_COUNT"
assert_link "the same skill links into ~/.agents/skills" "$H/.agents/skills/tdd" "$ROOT/skills/tdd"

# --- a name already visible to tcodex is skipped in ~/.agents/skills ---------

H="$(tmp)"
E="$(tmp)"
mkdir -p "$H/.tcodex/skills" "$E/skills/tdd"
ln -s "$E/skills/tdd" "$H/.tcodex/skills/tdd"
out="$(run "$H")"
assert_has "cross-dir conflict is reported" "$out" "skip tdd: ~/.tcodex/skills/tdd exists"
assert_absent "cross-dir conflict is not linked" "$H/.agents/skills/tdd"
assert_link "the untouched name links normally" "$H/.agents/skills/teach" "$ROOT/skills/teach"

# --- --replace takes the name over -------------------------------------------

H="$(tmp)"
E="$(tmp)"
mkdir -p "$H/.tclaude/skills" "$E/skills/tdd"
ln -s "$E/skills/tdd" "$H/.tclaude/skills/tdd"
out="$(run "$H" --replace tdd)"
assert_has "--replace prints the old target" "$out" "replace tdd: was $E/skills/tdd"
assert_link "--replace points the name at the repo" "$H/.tclaude/skills/tdd" "$ROOT/skills/tdd"

# --- a second run changes nothing and says the same thing --------------------

H="$(tmp)"
mkdir -p "$H/.tclaude" "$H/.claude"
out1="$(run "$H")"
snap1="$(snapshot "$H")"
out2="$(run "$H")"
snap2="$(snapshot "$H")"
[ "$out1" = "$out2" ] && ok "second run prints the same summary" || no "second run prints the same summary"
[ "$snap1" = "$snap2" ] && ok "second run leaves the tree identical" || no "second run leaves the tree identical"

# --- --dry-run writes nothing ------------------------------------------------

H="$(tmp)"
mkdir -p "$H/.tclaude" "$H/.claude"
snap1="$(snapshot "$H")"
out="$(run "$H" --dry-run)"
rc=$?
snap2="$(snapshot "$H")"
[ "$rc" = 0 ] && ok "--dry-run exits 0" || no "--dry-run exits 0" "exit $rc"
[ "$snap1" = "$snap2" ] && ok "--dry-run changes nothing" || no "--dry-run changes nothing"
assert_has "--dry-run reports the plan" "$out" "would link $SKILL_COUNT"
assert_absent "--dry-run creates no ~/.agents" "$H/.agents"

# --- --uninstall removes only our links --------------------------------------

H="$(tmp)"
E="$(tmp)"
mkdir -p "$H/.tclaude/skills" "$H/.claude/skills/keep-me" "$H/.tcodex/skills" "$E/skills/tdd"
ln -s "$E/skills/tdd" "$H/.tclaude/skills/tdd"
ln -s "$E/skills/tdd" "$H/.tcodex/skills/tdd"
run "$H" >/dev/null
ln -s "$ROOT/agents" "$H/.agents/agents"
out="$(run "$H" --uninstall)"
assert_has "--uninstall reports the exact count" "$out" "done: $((SKILL_COUNT * 2 + SKILL_COUNT - 1 - 1)) links removed"
assert_count "~/.agents/skills is emptied" "$H/.agents/skills" "0"
assert_count "~/.tclaude/skills keeps only the foreign entry" "$H/.tclaude/skills" "1"
assert_link "the foreign symlink survives" "$H/.tclaude/skills/tdd" "$E/skills/tdd"
assert_count "~/.claude/skills keeps the foreign directory" "$H/.claude/skills" "1"
assert_link "~/.tcodex/skills is untouched" "$H/.tcodex/skills/tdd" "$E/skills/tdd"
assert_absent "the legacy agents link is removed" "$H/.agents/agents"
assert_absent "our skill link is gone" "$H/.claude/skills/p3-mode"

# --- CLAUDE_CONFIG_DIR is detected and deduplicated --------------------------

H="$(tmp)"
C="$(tmp)"
out="$(env -u CODEX_HOME HOME="$H" CLAUDE_CONFIG_DIR="$C" "$INSTALL")"
assert_has "a custom CLAUDE_CONFIG_DIR is a target" "$out" "$C/skills"
assert_count "the custom config dir is filled" "$C/skills" "$SKILL_COUNT"
assert_absent "an absent ~/.claude is not created" "$H/.claude"

H="$(tmp)"
mkdir -p "$H/.tclaude"
out="$(env -u CODEX_HOME HOME="$H" CLAUDE_CONFIG_DIR="$H/.tclaude" "$INSTALL")"
n="$(printf '%s\n' "$out" | grep -c '~/.tclaude/skills')"
[ "$n" = 1 ] && ok "CLAUDE_CONFIG_DIR equal to ~/.tclaude is listed once" \
  || no "CLAUDE_CONFIG_DIR equal to ~/.tclaude is listed once" "listed $n times"

# --- --project still installs next to the repo -------------------------------

H="$(tmp)"
P="$(tmp)"
run "$H" --project "$P" >/dev/null
assert_count "project .agents/skills is filled" "$P/.agents/skills" "$SKILL_COUNT"
assert_count "project .claude/skills is filled" "$P/.claude/skills" "$SKILL_COUNT"
assert_absent "--project leaves the user home alone" "$H/.agents"

# --- usage errors exit 2 ------------------------------------------------------

run "$(tmp)" --nope >/dev/null 2>&1
rc=$?
[ "$rc" = 2 ] && ok "unknown flag exits 2" || no "unknown flag exits 2" "exit $rc"
run "$(tmp)" --target >/dev/null 2>&1
rc=$?
[ "$rc" = 2 ] && ok "missing value exits 2" || no "missing value exits 2" "exit $rc"

# --- values that look like options, or are empty, are rejected ----------------

for args in "--target --dry-run" "--replace --uninstall" "--project --help"; do
  W="$(tmp)"
  (cd "$W" && run "$(tmp)" $args >/dev/null 2>&1)
  rc=$?
  [ "$rc" = 2 ] && ok "$args exits 2" || no "$args exits 2" "exit $rc"
  assert_count "$args writes nothing in the working dir" "$W" "0"
done
W="$(tmp)"
(cd "$W" && run "$(tmp)" --target '' >/dev/null 2>&1)
rc=$?
[ "$rc" = 2 ] && ok "empty --target exits 2" || no "empty --target exits 2" "exit $rc"
assert_count "empty --target writes nothing" "$W" "0"

# --- a dangling link into this repo is ours: pruned and uninstalled -----------

H="$(tmp)"
mkdir -p "$H/.claude/skills"
ln -s "$ROOT/skills/removed-skill" "$H/.claude/skills/removed-skill"
out="$(run "$H")"
assert_has "install prunes a dangling link into this repo" "$out" "prune removed-skill"
assert_absent "the dangling link is gone after install" "$H/.claude/skills/removed-skill"
ln -s "$ROOT/skills/removed-skill" "$H/.claude/skills/removed-skill"
run "$H" --uninstall >/dev/null
assert_absent "uninstall removes a dangling link into this repo" "$H/.claude/skills/removed-skill"
E="$(tmp)"
ln -s "$E/gone" "$H/.claude/skills/foreign-dangling"
run "$H" >/dev/null
run "$H" --uninstall >/dev/null
assert_link "a dangling foreign link is never touched" "$H/.claude/skills/foreign-dangling" "$E/gone"

# --- links from another p3-stack checkout are repointed -----------------------

H="$(tmp)"
B="$(tmp)"
mkdir -p "$H/.claude/skills"
cp -R "$ROOT/skills" "$ROOT/install.sh" "$ROOT/UPSTREAM.md" "$B/"
ln -s "$B/skills/p3-mode" "$H/.claude/skills/p3-mode"
out="$(run "$H")"
assert_has "a link from another checkout is relinked" "$out" "relink p3-mode"
assert_link "the relinked entry points into this repo" "$H/.claude/skills/p3-mode" "$ROOT/skills/p3-mode"

# --- a look-alike skill library is not a p3-stack checkout -------------------

H="$(tmp)"
L="$(tmp)"
mkdir -p "$H/.claude/skills" "$L/skills/tdd" "$L/skills/p3-mode"
printf -- '---\nname: p3-mode\n---\n' > "$L/skills/p3-mode/SKILL.md"
printf '#!/bin/sh\n' > "$L/install.sh"
ln -s "$L/skills/tdd" "$H/.claude/skills/tdd"
out="$(run "$H")"
assert_has "a look-alike library is skipped as foreign" "$out" "skip tdd: foreign symlink"
assert_link "a look-alike library link is untouched" "$H/.claude/skills/tdd" "$L/skills/tdd"

# --- Codex dirs: another checkout or a dangling link does not block ----------

H="$(tmp)"
B="$(tmp)"
mkdir -p "$H/.tcodex/skills"
cp -R "$ROOT/skills" "$ROOT/install.sh" "$ROOT/UPSTREAM.md" "$B/"
ln -s "$B/skills/tdd" "$H/.tcodex/skills/tdd"
ln -s "$(tmp)/gone" "$H/.tcodex/skills/teach"
run "$H" >/dev/null
assert_link "another checkout in ~/.tcodex does not block tdd" "$H/.agents/skills/tdd" "$ROOT/skills/tdd"
assert_link "a dangling link in ~/.tcodex does not block teach" "$H/.agents/skills/teach" "$ROOT/skills/teach"

# --- HOME with a trailing slash still prints ~ paths -------------------------

H="$(tmp)"
mkdir -p "$H/.claude"
out="$(env -u CLAUDE_CONFIG_DIR -u CODEX_HOME HOME="$H/" "$INSTALL")"
assert_has "HOME/ prints ~/.claude/skills" "$out" "~/.claude/skills"

# --- HOME and targets with spaces --------------------------------------------

S="$(tmp)/my home"
mkdir -p "$S/.claude"
run "$S" >/dev/null
assert_count "a HOME with a space is filled" "$S/.claude/skills" "$SKILL_COUNT"

# --- install.sh called through a symlink -------------------------------------

H="$(tmp)"
BIN="$(tmp)"
ln -s "$INSTALL" "$BIN/p3-install"
mkdir -p "$H/.claude"
env -u CLAUDE_CONFIG_DIR -u CODEX_HOME HOME="$H" "$BIN/p3-install" >/dev/null
rc=$?
[ "$rc" = 0 ] && ok "a symlinked install.sh exits 0" || no "a symlinked install.sh exits 0" "exit $rc"
assert_link "a symlinked install.sh links into the repo" "$H/.claude/skills/p3-mode" "$ROOT/skills/p3-mode"
assert_absent "a symlinked install.sh makes no '*' link" "$H/.claude/skills/*"

# --- CODEX_HOME and ~/.codex names block ~/.agents/skills ---------------------

H="$(tmp)"
X="$(tmp)"
E="$(tmp)"
mkdir -p "$H/.codex/skills" "$X/skills"
ln -s "$E" "$H/.codex/skills/tdd"
ln -s "$E" "$X/skills/teach"
env -u CLAUDE_CONFIG_DIR HOME="$H" CODEX_HOME="$X" "$INSTALL" >/dev/null
assert_absent "~/.codex/skills/tdd blocks ~/.agents/skills/tdd" "$H/.agents/skills/tdd"
assert_absent "CODEX_HOME/skills/teach blocks ~/.agents/skills/teach" "$H/.agents/skills/teach"

# --- --dry-run --uninstall changes nothing -----------------------------------

H="$(tmp)"
mkdir -p "$H/.claude"
run "$H" >/dev/null
snap1="$(snapshot "$H")"
run "$H" --uninstall --dry-run >/dev/null
snap2="$(snapshot "$H")"
[ "$snap1" = "$snap2" ] && ok "--uninstall --dry-run changes nothing" || no "--uninstall --dry-run changes nothing"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
