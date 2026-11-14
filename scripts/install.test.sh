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
  (cd "$1" && find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r p; do
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
assert_has "--uninstall reports removals" "$out" "removed"
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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
