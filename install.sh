#!/usr/bin/env bash
# Install p3-stack skills for T3 Code.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.agents/skills"

if [[ "${1:-}" == "--project" ]]; then
  TARGET="${2:?usage: ./install.sh --project /path/to/repo}/.agents/skills"
fi

mkdir -p "$TARGET"
AGENTS_LINK="$(dirname "$TARGET")/agents"
installed=0
skipped=0

for skill in "$ROOT"/skills/*/; do
  name="$(basename "$skill")"
  if [[ -L "$TARGET/$name" ]]; then
    rm "$TARGET/$name"
  elif [[ -e "$TARGET/$name" ]]; then
    printf 'skip %s (exists and is not a symlink)\n' "$name"
    skipped=$((skipped + 1))
    continue
  fi
  ln -s "$skill" "$TARGET/$name"
  installed=$((installed + 1))
done

# agents/ sits beside skills/ so p3-mode resolves ../../agents/<name>.md after install.
agents_note="agents -> $AGENTS_LINK"
if [[ -L "$AGENTS_LINK" ]]; then
  if [[ "$(readlink "$AGENTS_LINK")" == "$ROOT/agents" ]]; then
    rm "$AGENTS_LINK"
    ln -s "$ROOT/agents" "$AGENTS_LINK"
  else
    agents_note="agents skipped ($AGENTS_LINK points elsewhere: $(readlink "$AGENTS_LINK"))"
  fi
elif [[ -e "$AGENTS_LINK" ]]; then
  agents_note="agents skipped ($AGENTS_LINK exists and is not a symlink)"
else
  ln -s "$ROOT/agents" "$AGENTS_LINK"
fi

printf 'linked %d skills into %s' "$installed" "$TARGET"
if [[ "$skipped" -gt 0 ]]; then
  printf ' (%d skipped)' "$skipped"
fi
printf '; %s\n' "$agents_note"
