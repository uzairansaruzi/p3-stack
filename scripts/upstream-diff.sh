#!/usr/bin/env bash
# upstream-diff.sh: list what changed in upstream pstack since each skill's aligned commit,
# and reconcile that against UPSTREAM.md. Read-only: never edits files, never pushes.
#
# usage: scripts/upstream-diff.sh [--to <rev>] [--upstream <path|url>] [--skill <name>]
#                                 [--files] [--json] [--no-fetch]
# exit:  0 nothing to do   10 changes or warnings need handling   2 error
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UP_MD="$ROOT/UPSTREAM.md"
TO="" UPSTREAM="" ONLY="" FILES=0 JSON=0 FETCH=1

die() { printf 'error: %s\n' "$*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) TO="${2:?--to needs a rev}"; shift 2 ;;
    --upstream) UPSTREAM="${2:?--upstream needs a path or url}"; shift 2 ;;
    --skill) ONLY="${2:?--skill needs a name}"; shift 2 ;;
    --files) FILES=1; shift ;;
    --json) JSON=1; shift ;;
    --no-fetch) FETCH=0; shift ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -f "$UP_MD" ]] || die "missing $UP_MD"

# shellcheck source=lib/upstream.sh
source "$ROOT/scripts/lib/upstream.sh"

up_open "$UPSTREAM" "$TO" "$FETCH"

# --- UPSTREAM.md tables ------------------------------------------------------
load_mapping

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
: > "$TMP/ignore.re"; : > "$TMP/ignore.glob"
while IFS=$'\t' read -r paths action _; do
  [[ "$action" == "ignore" ]] || continue
  IFS=',、' read -ra parts <<< "$paths"
  for g in "${parts[@]}"; do
    g="$(printf '%s' "$g" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -n "$g" ]] || continue
    printf '%s\t%s\n' "$(glob2re "$g")" "$g" >> "$TMP/ignore.re"
  done
done < <(table "有意缺口与忽略路径")

unit_of() { # path relative to subtree -> unit key
  case "$1" in
    skills/*) local r="${1#skills/}"; echo "skills/${r%%/*}" ;;
    agents/*) echo "$1" ;;
    *) echo "${1%%/*}" ;;
  esac
}

# --- changes per unit --------------------------------------------------------
# global diff from pin decides which units to look at; each unit is then re-diffed from its own alignment.
G diff --name-status --no-renames "$PIN_FULL" "$TO_FULL" -- "$SUBTREE/" | sed "s|\t$SUBTREE/|\t|" > "$TMP/global.tsv" || true
cut -f2 "$TMP/global.tsv" | while read -r p; do unit_of "$p"; done | sort -u > "$TMP/units.txt"

OUT=() ; WARNS=()
n_new=0 n_mod=0 n_del=0 n_ign=0
: > "$TMP/ign.count"

for u in $(cat "$TMP/units.txt"); do
  idx="$(row_of "$u")"
  base="$PIN_FULL" align="" p3="(none)"
  if [[ -n "$idx" ]]; then
    p3="${M_P3[$idx]}"; align="${M_AL[$idx]}"
    if [[ "$align" != "—" && -n "$align" ]]; then
      if b="$(G rev-parse -q --verify "$align^{commit}" 2>/dev/null)"; then base="$b"
      else WARNS+=("WARN $u alignment $align does not resolve upstream"); fi
    fi
  fi
  G diff --name-status --no-renames "$base" "$TO_FULL" -- "$SUBTREE/$u" "$SUBTREE/$u/" \
    | sed "s|\t$SUBTREE/|\t|" > "$TMP/u.tsv" || true
  # drop ignored paths, count them per pattern
  awk -F'\t' -v ire="$TMP/ignore.re" -v cnt="$TMP/ign.count" '
    BEGIN { while ((getline l < ire) > 0) { split(l, a, "\t"); re[++n] = a[1]; gl[n] = a[2] } }
    { hit = 0; for (i = 1; i <= n; i++) if ($2 ~ re[i]) { print gl[i] >> cnt; hit = 1; break }
      if (!hit) print }' "$TMP/u.tsv" > "$TMP/u.kept"
  [[ -s "$TMP/u.kept" ]] || continue
  name="${u#skills/}"; p3name="${p3#skills/}"
  if [[ -n "$ONLY" && "$ONLY" != "$name" && "$ONLY" != "$p3name" && "$ONLY" != "$u" ]]; then continue; fi
  [[ -n "$idx" ]] || WARNS+=("WARN $u has upstream changes but no mapping row")
  a=$(grep -c '^A' "$TMP/u.kept" || true); m=$(grep -c '^M' "$TMP/u.kept" || true); d=$(grep -c '^D' "$TMP/u.kept" || true)
  paths=(); while IFS=$'\t' read -r _ p; do paths+=("$SUBTREE/$p"); done < "$TMP/u.kept"
  G diff --numstat --no-renames "$base" "$TO_FULL" -- "${paths[@]}" > "$TMP/u.num" 2>/dev/null || true
  plus=$(awk '$1 ~ /^[0-9]+$/ {s += $1} END {print s + 0}' "$TMP/u.num")
  minus=$(awk '$2 ~ /^[0-9]+$/ {s += $2} END {print s + 0}' "$TMP/u.num")
  if ! G cat-file -e "$base:$SUBTREE/$u" 2>/dev/null; then kind=NEW; n_new=$((n_new + 1))
  elif ! G cat-file -e "$TO_FULL:$SUBTREE/$u" 2>/dev/null; then kind=DELETED; n_del=$((n_del + 1))
  else kind=MOD; n_mod=$((n_mod + 1)); fi
  cp "$TMP/u.kept" "$TMP/files.$(printf '%s' "$u" | tr '/' '_')"
  cp "$TMP/u.num" "$TMP/num.$(printf '%s' "$u" | tr '/' '_')"
  OUT+=("$kind"$'\t'"$u"$'\t'"$a"$'\t'"$m"$'\t'"$d"$'\t'"$plus"$'\t'"$minus"$'\t'"$p3"$'\t'"${align:-—}"$'\t'"$(S "$base")")
done

# --- reconciliation (independent of the diff) ---------------------------------
declare -A P3_LISTED=()
for i in "${!M_UP[@]}"; do
  [[ "${M_P3[$i]}" == "—" ]] || P3_LISTED["${M_P3[$i]}"]=1
  if [[ "${M_ST[$i]}" == "ported" && "${M_P3[$i]}" != "—" && ! -e "$ROOT/${M_P3[$i]}" ]]; then
    WARNS+=("WARN ${M_UP[$i]} is ported but ${M_P3[$i]} does not exist in p3")
  fi
  al="${M_AL[$i]}"
  if [[ "$al" != "—" && -n "$al" ]] && b="$(G rev-parse -q --verify "$al^{commit}" 2>/dev/null)"; then
    if [[ "$b" != "$PIN_FULL" ]] && G merge-base --is-ancestor "$b" "$PIN_FULL" 2>/dev/null; then
      WARNS+=("WARN ${M_UP[$i]} aligned to $al, which is older than pin $(S "$PIN_FULL")")
    fi
  fi
done
for d in "$ROOT"/skills/*/ "$ROOT"/agents/*.md; do
  [[ -e "$d" ]] || continue
  rel="${d#"$ROOT"/}"; rel="${rel%/}"
  [[ -n "${P3_LISTED[$rel]:-}" ]] || WARNS+=("WARN $rel has no mapping row (register p3-only skills explicitly)")
done
# upstream units present at the target but not registered at all
{ G ls-tree --name-only "$TO_FULL" "$SUBTREE/skills/" | sed "s|^$SUBTREE/||"; } 2>/dev/null | while read -r u; do
  [[ -n "$(row_of "$u")" ]] || echo "WARN $u exists upstream but has no mapping row"
done > "$TMP/unreg.txt" || true
while read -r l; do [[ -n "$l" ]] && WARNS+=("$l"); done < "$TMP/unreg.txt"
mapfile -t WARNS < <(printf '%s\n' "${WARNS[@]:-}" | sed '/^$/d' | sort -u)

n_ign=$(wc -l < "$TMP/ign.count" | tr -d ' ')

# --- output ------------------------------------------------------------------
if [[ "$JSON" == 1 ]]; then
  printf '{"pin":"%s","to":"%s","commits":%s,' "$(S "$PIN_FULL")" "$(S "$TO_FULL")" "$(G rev-list --count "$PIN_FULL..$TO_FULL" -- "$SUBTREE/")"
  printf '"changes":['
  sep=""
  for r in "${OUT[@]:-}"; do
    [[ -n "$r" ]] || continue
    IFS=$'\t' read -r kind u a m d plus minus p3 al base <<< "$r"
    printf '%s{"kind":"%s","unit":"%s","added":%s,"modified":%s,"deleted":%s,"plus":%s,"minus":%s,"p3":"%s","aligned":"%s"}' \
      "$sep" "$kind" "$u" "$a" "$m" "$d" "$plus" "$minus" "$p3" "$al"; sep=","
  done
  printf '],"warnings":['
  sep=""; for w in "${WARNS[@]:-}"; do [[ -n "$w" ]] && { printf '%s"%s"' "$sep" "${w//\"/\\\"}"; sep=","; }; done
  printf '],"summary":{"new":%s,"mod":%s,"deleted":%s,"ignored":%s}}\n' "$n_new" "$n_mod" "$n_del" "$n_ign"
else
  printf 'upstream %s: %s -> %s  (%s commits, %s files)\n' "$SUBTREE" "$(S "$PIN_FULL")" "$(S "$TO_FULL")" \
    "$(G rev-list --count "$PIN_FULL..$TO_FULL" -- "$SUBTREE/")" "$(wc -l < "$TMP/global.tsv" | tr -d ' ')"
  for n in "${NOTES[@]:-}"; do [[ -n "$n" ]] && printf 'note: %s\n' "$n"; done
  for r in "${OUT[@]:-}"; do
    [[ -n "$r" ]] || continue
    IFS=$'\t' read -r kind u a m d plus minus p3 al base <<< "$r"
    cnt=""; [[ "$a" -gt 0 ]] && cnt+="A=$a "; [[ "$m" -gt 0 ]] && cnt+="M=$m "; [[ "$d" -gt 0 ]] && cnt+="D=$d "
    printf '%-8s %-52s %-14s +%s -%s  p3: %s  aligned=%s\n' "$kind" "$u" "${cnt% }" "$plus" "$minus" "$p3" "$al"
    if [[ "$FILES" == 1 || -n "$ONLY" ]]; then
      f="$TMP/files.$(printf '%s' "$u" | tr '/' '_')"
      while IFS=$'\t' read -r st p; do printf '           %s %s\n' "$st" "$p"; done < "$f"
    fi
    if [[ -n "$ONLY" ]]; then
      G log --oneline "$base..$TO_FULL" -- "$SUBTREE/$u" | sed 's/^/           commit /'
    fi
  done
  if [[ "$n_ign" -gt 0 ]]; then
    sort "$TMP/ign.count" | uniq -c | while read -r c g; do printf 'ignored  %s (%s files)\n' "$g" "$c"; done
  fi
  for w in "${WARNS[@]:-}"; do [[ -n "$w" ]] && printf '%s\n' "$w"; done
fi

nwarn=0; for w in "${WARNS[@]:-}"; do [[ -n "$w" ]] && nwarn=$((nwarn + 1)); done
code=0; if [[ $((n_new + n_mod + n_del + nwarn)) -gt 0 ]]; then code=10; fi
if [[ "$JSON" != 1 ]]; then
  printf 'summary: new=%s mod=%s deleted=%s ignored=%s warnings=%s        exit %s\n' "$n_new" "$n_mod" "$n_del" "$n_ign" "$nwarn" "$code"
  if [[ "$code" == 0 ]]; then :; else
    printf 'hint: after a full sync set "pin: %s" (and pin-date, pin-version, synced-on) in UPSTREAM.md\n' "$(S "$TO_FULL")"
  fi
fi
exit "$code"
