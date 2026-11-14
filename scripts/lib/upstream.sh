#!/usr/bin/env bash
# Shared helpers for upstream-diff.sh and parity-check.sh. Source it; do not run it.
# Expects ROOT, UP_MD, and the caller's own die().

header() { grep -m1 "^$1:" "$UP_MD" | sed 's/^[^:]*: *//; s/[[:space:]]*$//'; }

# table <heading-prefix>: print rows of the first table under "## <prefix>…" as tab-separated cells.
table() {
  awk -v h="$1" '
    /^## / { in_s = (index($0, "## " h) == 1); hdr = 0; next }
    in_s && /^\|/ {
      line = $0; gsub(/`/, "", line)
      n = split(line, f, /\|/)
      if (!hdr) { hdr = 1; next }
      if (f[2] ~ /^[ \t]*:?-+:?[ \t]*$/) next
      row = ""
      for (i = 2; i < n; i++) { v = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", v); row = row (i > 2 ? "\t" : "") v }
      print row
    }' "$UP_MD"
}

glob2re() { # shell-style glob (** crosses dirs) -> anchored ERE
  printf '%s' "$1" | sed -e 's/[.+^$(){}|\\]/\\&/g' -e 's/\*\*/\x01/g' -e 's/\*/[^\/]*/g' \
    -e 's/\x01/.*/g' -e 's/?/[^\/]/g' -e 's/^/^/' -e 's/$/$/'
}

# up_open <upstream-arg> <to-rev> <fetch 0|1>
# Sets PIN, SUBTREE, UP, MAIN, PIN_FULL, TO_FULL, NOTES; defines G (git in the upstream copy) and S (short sha).
up_open() {
  local arg="$1" to="$2" fetch="$3"
  PIN="$(header pin)"; SUBTREE="$(header subtree)"; SUBTREE="${SUBTREE%/}"
  [[ -n "$PIN" && -n "$SUBTREE" ]] || die "UPSTREAM.md needs pin: and subtree: lines"
  UP="${arg:-${P3_UPSTREAM_CACHE:-$HOME/.cache/p3-stack/cursor-plugins}}"
  NOTES=()
  if [[ ! -d "$UP/.git" && ! -f "$UP/HEAD" ]]; then
    if [[ -z "$arg" || "$arg" == http* || "$arg" == git@* ]]; then
      local url="${arg:-$(header upstream)}"
      mkdir -p "$(dirname "$UP")"
      git clone -q --filter=blob:none "$url" "$UP" || die "clone failed: $url"
    else
      die "no git repository at $UP"
    fi
  elif [[ "$fetch" == 1 ]]; then
    git -C "$UP" fetch -q origin 2>/dev/null || NOTES+=("fetch failed, using local objects")
  fi
  MAIN=""
  local r
  for r in origin/main main origin/master master HEAD; do
    if git -C "$UP" rev-parse -q --verify "$r^{commit}" >/dev/null 2>&1; then MAIN="$r"; break; fi
  done
  [[ -n "$MAIN" ]] || die "cannot find upstream main in $UP"
  PIN_FULL="$(G rev-parse -q --verify "$PIN^{commit}")" || die "pin $PIN not found upstream"
  [[ -n "$to" ]] || to="$(G log -1 --format=%H "$MAIN" -- "$SUBTREE")"
  TO_FULL="$(G rev-parse -q --verify "$to^{commit}")" || die "target $to not found upstream"
}
G() { git -C "$UP" "$@"; }
S() { printf '%s' "${1:0:7}"; }

# load_mapping: fills M_UP, M_P3, M_AL, M_ST from the 映射 table.
load_mapping() {
  M_UP=() M_P3=() M_AL=() M_ST=()
  local a b c d
  while IFS=$'\t' read -r a b c d _; do
    [[ -n "$a" ]] || continue
    M_UP+=("$a"); M_P3+=("$b"); M_AL+=("$c"); M_ST+=("$d")
  done < <(table "映射")
  [[ ${#M_UP[@]} -gt 0 ]] || die "UPSTREAM.md has no rows under '## 映射'"
}
row_of() { # row_of <upstream-unit> -> index or empty
  local i; for i in "${!M_UP[@]}"; do if [[ "${M_UP[$i]}" == "$1" ]]; then echo "$i"; return 0; fi; done
  return 0
}
