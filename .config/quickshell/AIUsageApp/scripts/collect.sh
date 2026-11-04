#!/usr/bin/env bash
#
# Runs every provider script in providers/ and combines their output into
# one {"providers": [...]} array -- the single data source for the
# Quickshell dropdown panel (AIUsageWindow.qml).
#
# To add a new AI tool: drop an executable script into providers/ that
# prints {id, name, plan, available, limits[], tokens_by_day[], tokens_by_model[]}
# (see providers/claude-code.sh for a full example, providers/codex.sh for
# the minimal "not wired up yet" shape). Nothing else needs to change —
# this script picks it up automatically.

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/providers"
force="${1:-}"

results=()
for script in "$DIR"/*.sh; do
    [ -x "$script" ] || continue
    out=$("$script" "$force" 2>/dev/null)
    if [ -z "$out" ] || ! jq -e . >/dev/null 2>&1 <<<"$out"; then
        name=$(basename "$script" .sh)
        out=$(jq -nc --arg id "$name" \
            '{id:$id, name:$id, plan:"", available:false, message:"provider script failed", limits:[], tokens_by_day:[], tokens_by_model:[]}')
    fi
    results+=("$out")
done

printf '%s\n' "${results[@]}" | jq -sc '{providers: .}'
