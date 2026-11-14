#!/usr/bin/env bash
# Install p3-stack skills for every agent harness on this machine.
# Default is user-level: one symlink per skill in each skills directory that
# already exists. Entries that are not p3-stack links are skipped, never removed.
set -euo pipefail

# Follow symlinks to this script, so a link such as ~/bin/p3-install works.
self="${BASH_SOURCE[0]}"
while [ -L "$self" ]; do
  link="$(readlink "$self")"
  case "$link" in
    /*) self="$link" ;;
    *) self="$(dirname "$self")/$link" ;;
  esac
done
REPO="$(cd -P "$(dirname "$self")" && pwd -P)"
SKILLS_SRC="$REPO/skills"
AGENTS_SRC="$REPO/agents"
if [ ! -f "$SKILLS_SRC/p3-mode/SKILL.md" ]; then
  printf 'error: %s is not a p3-stack checkout (no skills/p3-mode/SKILL.md)\n' "$REPO" >&2
  exit 2
fi
HOME="${HOME:?HOME is not set}"
while [ "$HOME" != "/" ] && [ "${HOME%/}" != "$HOME" ]; do HOME="${HOME%/}"; done

DRY=0
UNINSTALL=0
EXPLICIT_TARGETS=()
PROJECTS=()
REPLACE=()

usage() {
  cat <<'EOF'
usage: ./install.sh [options]

Installs every skills/<name> as a symlink into each user-level skills directory
that already exists on this machine:

  ~/.agents/skills         codex, tcodex, T3 Codex   (created when missing)
  <config home>/skills     claude, tclaude, T3 Claude, for an existing
                           $CLAUDE_CONFIG_DIR, ~/.tclaude, or ~/.claude

options:
  --target <dir>     install into <dir> instead of auto-detecting (repeatable)
  --project <repo>   install into <repo>/.agents/skills and <repo>/.claude/skills
  --replace <name>   take over an existing entry with this name (repeatable);
                     prints what it pointed to before replacing it
  --uninstall        remove only the links that point into this repo
  --dry-run          print the plan, change nothing
  -h, --help         this text

An entry that is not a p3-stack symlink is skipped and reported. Exits 0 when
the run succeeds, 2 on a usage error.
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 2; }

# --- portable path handling (no readlink -f, no realpath) --------------------

to_abs() {
  case "$1" in
    /*) resolve "$1" ;;
    *) resolve "$(pwd -P)/$1" ;;
  esac
}

# resolve <abs-path>: canonical form. Symlinks in the existing part are
# followed; a missing tail is appended unchanged.
resolve() {
  local p="$1" suffix="" head base
  while [ "$p" != "/" ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done
  head="$p"
  while [ "$head" != "/" ] && [ ! -e "$head" ]; do
    suffix="/$(basename "$head")$suffix"
    head="$(dirname "$head")"
  done
  if [ -d "$head" ]; then
    base="$(cd -P "$head" && pwd -P)"
  elif [ -e "$head" ]; then
    base="$(cd -P "$(dirname "$head")" && pwd -P)/$(basename "$head")"
  else
    base="/"
  fi
  if [ "$base" = "/" ]; then printf '%s\n' "/${suffix#/}"; else printf '%s%s\n' "$base" "$suffix"; fi
}

disp() {
  case "$1" in
    "$HOME"/*) printf '~%s\n' "${1#"$HOME"}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# --- ownership ---------------------------------------------------------------

# link_target <link>: absolute target of a symlink, resolved even when the
# target no longer exists (a skill removed upstream leaves a dangling link).
link_target() {
  local t
  t="$(readlink "$1")"
  case "$t" in
    /*) resolve "$t" ;;
    *) resolve "$(dirname "$1")/$t" ;;
  esac
}

# own_skill <entry>: a symlink into this checkout's skills/, dangling or not.
own_skill() {
  [ -L "$1" ] || return 1
  case "$(link_target "$1")" in
    "$REPO"/skills/*) return 0 ;;
  esac
  return 1
}

# other_checkout <entry> <name>: a symlink to skills/<name> of another p3-stack
# checkout that still exists (same layout, has skills/p3-mode/SKILL.md).
other_checkout() {
  local t root
  [ -L "$1" ] || return 1
  t="$(link_target "$1")"
  [ "$(basename "$t")" = "$2" ] || return 1
  root="$(dirname "$t")"
  [ "$(basename "$root")" = "skills" ] || return 1
  [ -f "$root/p3-mode/SKILL.md" ] && [ -f "$(dirname "$root")/install.sh" ]
}

own_agents() {
  [ -L "$1" ] || return 1
  [ "$(link_target "$1")" = "$(resolve "$AGENTS_SRC")" ]
}

replace_wanted() {
  local r
  for r in ${REPLACE[@]+"${REPLACE[@]}"}; do
    if [ "$r" = "$1" ]; then return 0; fi
  done
  return 1
}

# --- targets -----------------------------------------------------------------

T_DIR=()
T_CANON=()
T_LABEL=()

add_target() {
  local abs canon i
  abs="$(to_abs "$1")"
  canon="$(resolve "$abs")"
  for i in ${T_CANON[@]+"${T_CANON[@]}"}; do
    if [ "$i" = "$canon" ]; then return 0; fi
  done
  T_DIR+=("$abs")
  T_CANON+=("$canon")
  T_LABEL+=("$2")
}

is_codex_dir() {
  local want="$1" d
  for d in "$HOME/.agents/skills" "$HOME/.tcodex/skills" "$HOME/.codex/skills"; do
    if [ "$(resolve "$d")" = "$want" ]; then return 0; fi
  done
  if [ -n "${CODEX_HOME:-}" ] && [ "$(resolve "$CODEX_HOME/skills")" = "$want" ]; then
    return 0
  fi
  return 1
}

codex_dirs() {
  local d
  for d in "$HOME/.agents/skills" "$HOME/.tcodex/skills" "$HOME/.codex/skills"; do
    if [ -d "$d" ]; then printf '%s\n' "$d"; fi
  done
  if [ -n "${CODEX_HOME:-}" ] && [ -d "$CODEX_HOME/skills" ]; then
    printf '%s\n' "$CODEX_HOME/skills"
  fi
}

# --- argument parsing --------------------------------------------------------

# need_value <option> <what> <argc> <value>: the option's value must be
# present, non-empty, and not another option.
need_value() {
  if [ "$3" -lt 2 ] || [ -z "$4" ]; then die "$1 needs $2"; fi
  case "$4" in -*) die "$1 needs $2, got option $4" ;; esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    need_value "$1" "a directory" $# "${2-}"; EXPLICIT_TARGETS+=("$2"); shift 2 ;;
    --project)   need_value "$1" "a repo path" $# "${2-}"; PROJECTS+=("$2"); shift 2 ;;
    --replace)   need_value "$1" "a skill name" $# "${2-}"; REPLACE+=("$2"); shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "unknown argument: $1 (see --help)" ;;
  esac
done

if [ ${#EXPLICIT_TARGETS[@]} -gt 0 ] || [ ${#PROJECTS[@]} -gt 0 ]; then
  for t in ${EXPLICIT_TARGETS[@]+"${EXPLICIT_TARGETS[@]}"}; do
    add_target "$t" "explicit target"
  done
  for p in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
    add_target "$(to_abs "$p")/.agents/skills" "project, codex"
    add_target "$(to_abs "$p")/.claude/skills" "project, claude"
  done
else
  add_target "$HOME/.agents/skills" "codex, tcodex, T3 Codex"
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "$CLAUDE_CONFIG_DIR" ]; then
    add_target "$CLAUDE_CONFIG_DIR/skills" "claude, CLAUDE_CONFIG_DIR"
  fi
  if [ -d "$HOME/.tclaude" ]; then
    add_target "$HOME/.tclaude/skills" "tclaude, T3 Claude"
  fi
  if [ -d "$HOME/.claude" ]; then
    add_target "$HOME/.claude/skills" "claude"
  fi
fi

[ ${#T_DIR[@]} -gt 0 ] || die "no install target"

# --- uninstall ---------------------------------------------------------------

if [ "$UNINSTALL" = 1 ]; then
  printf 'p3-stack uninstall%s\nrepo: %s\n\n' "$([ "$DRY" = 1 ] && printf ' (dry run)')" "$REPO"
  total=0
  i=0
  while [ "$i" -lt "${#T_DIR[@]}" ]; do
    dir="${T_DIR[$i]}"
    printf '%s  [%s]\n' "$(disp "$dir")" "${T_LABEL[$i]}"
    if [ ! -d "$dir" ]; then
      printf '  nothing to do, directory does not exist\n'
      i=$((i + 1))
      continue
    fi
    removed=0
    for entry in "$dir"/*; do
      [ -L "$entry" ] || continue
      if own_skill "$entry"; then
        if [ "$DRY" = 1 ]; then printf '  would remove %s\n' "$(basename "$entry")"; fi
        [ "$DRY" = 1 ] || rm "$entry"
        removed=$((removed + 1))
      fi
    done
    printf '  removed %d links\n' "$removed"
    total=$((total + removed))
    legacy="$(dirname "$dir")/agents"
    if own_agents "$legacy"; then
      printf '  removed legacy agents link %s\n' "$(disp "$legacy")"
      [ "$DRY" = 1 ] || rm "$legacy"
    fi
    i=$((i + 1))
  done
  if [ "$DRY" = 1 ]; then
    printf '\ndry run: %d links would be removed, nothing changed\n' "$total"
  else
    printf '\ndone: %d links removed\n' "$total"
  fi
  exit 0
fi

# --- install -----------------------------------------------------------------

printf 'p3-stack install%s\nrepo: %s\n\n' "$([ "$DRY" = 1 ] && printf ' (dry run)')" "$REPO"
grand_linked=0
grand_skipped=0

i=0
while [ "$i" -lt "${#T_DIR[@]}" ]; do
  dir="${T_DIR[$i]}"
  canon="${T_CANON[$i]}"
  label="${T_LABEL[$i]}"
  codex=0
  if is_codex_dir "$canon"; then codex=1; fi

  printf '%s  [%s]\n' "$(disp "$dir")" "$label"

  if [ -e "$dir" ] && [ ! -d "$dir" ]; then
    printf 'error: %s exists and is not a directory\n' "$dir" >&2
    exit 1
  fi
  if [ ! -d "$dir" ]; then
    if [ "$DRY" = 0 ]; then
      if ! mkdir -p "$dir" 2>/dev/null; then
        printf 'error: cannot create %s\n' "$dir" >&2
        exit 1
      fi
    fi
  fi

  linked=0
  skipped=0
  replaced=0
  reasons=()

  for src in "$SKILLS_SRC"/*/; do
    src="${src%/}"
    name="$(basename "$src")"
    entry="$dir/$name"

    if [ -L "$entry" ]; then
      if own_skill "$entry" && [ "$(link_target "$entry")" = "$(resolve "$src")" ]; then
        linked=$((linked + 1))
      elif own_skill "$entry" || other_checkout "$entry" "$name"; then
        # ours but stale, or the same skill from another p3-stack checkout: repoint
        reasons+=("relink $name: was $(disp "$(link_target "$entry")")")
        [ "$DRY" = 1 ] || { rm "$entry"; ln -s "$src" "$entry"; }
        linked=$((linked + 1))
      elif replace_wanted "$name"; then
        reasons+=("replace $name: was $(disp "$(link_target "$entry")")")
        [ "$DRY" = 1 ] || { rm "$entry"; ln -s "$src" "$entry"; }
        replaced=$((replaced + 1))
      else
        reasons+=("skip $name: foreign symlink -> $(disp "$(link_target "$entry")")")
        skipped=$((skipped + 1))
      fi
      continue
    fi

    if [ -e "$entry" ]; then
      if replace_wanted "$name"; then
        reasons+=("replace $name: was a file or directory at $(disp "$entry")")
        [ "$DRY" = 1 ] || { rm -rf "$entry"; ln -s "$src" "$entry"; }
        replaced=$((replaced + 1))
      else
        reasons+=("skip $name: exists and is not a symlink")
        skipped=$((skipped + 1))
      fi
      continue
    fi

    conflict=""
    if [ "$codex" = 1 ]; then
      while IFS= read -r xd; do
        if [ -z "$xd" ]; then continue; fi
        if [ "$(resolve "$xd")" = "$canon" ]; then continue; fi
        if [ -e "$xd/$name" ] || [ -L "$xd/$name" ]; then
          if own_skill "$xd/$name"; then continue; fi
          conflict="$xd/$name"
          break
        fi
      done <<EOF
$(codex_dirs)
EOF
    fi

    if [ -n "$conflict" ]; then
      reasons+=("skip $name: $(disp "$conflict") exists (codex reads both dirs)")
      skipped=$((skipped + 1))
      continue
    fi

    [ "$DRY" = 1 ] || ln -s "$src" "$entry"
    linked=$((linked + 1))
  done

  # links into this repo whose skill no longer exists (removed upstream)
  for entry in "$dir"/*; do
    if [ -L "$entry" ] && own_skill "$entry" && [ ! -e "$entry" ]; then
      reasons+=("prune $(basename "$entry"): skill no longer in this repo")
      [ "$DRY" = 1 ] || rm "$entry"
    fi
  done

  if [ "$DRY" = 1 ]; then
    printf '  would link %d, would skip %d\n' "$linked" "$skipped"
  else
    printf '  linked %d, skipped %d\n' "$linked" "$skipped"
  fi
  if [ "$replaced" -gt 0 ]; then printf '  replaced %d per --replace\n' "$replaced"; fi
  for r in ${reasons[@]+"${reasons[@]}"}; do printf '  %s\n' "$r"; done

  legacy="$(dirname "$dir")/agents"
  if own_agents "$legacy"; then
    printf '  note: kept legacy link %s (./install.sh --uninstall removes it)\n' "$(disp "$legacy")"
  fi

  grand_linked=$((grand_linked + linked))
  grand_skipped=$((grand_skipped + skipped))
  i=$((i + 1))
done

if [ "$DRY" = 1 ]; then
  printf '\ndry run: %d links would be written, %d skipped, nothing changed\n' "$grand_linked" "$grand_skipped"
else
  printf '\ndone: %d links written, %d skipped\n' "$grand_linked" "$grand_skipped"
  printf 'next: open a new thread, then run /setup-p3 to map each role to a model\n'
fi
