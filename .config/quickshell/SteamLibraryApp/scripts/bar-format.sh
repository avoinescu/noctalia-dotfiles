#!/usr/bin/env bash
#
# Compact bar text/tooltip for the steam-library plugin's bar.luau capsule,
# derived from collect.sh's output. Click opens the full panel instead.

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data=$("$DIR/collect.sh")

configured=$(jq -r '.configured' <<<"$data")
reason=$(jq -r '.reason // ""' <<<"$data")

if [ "$configured" != "true" ]; then
    msg=$(jq -r '.message // "not configured"' <<<"$data")
    jq -nc --arg m "$msg" '{text: "steam: setup", tooltip: $m, class: "critical"}'
    exit 0
fi

if [ "$reason" = "fetch_failed" ]; then
    msg=$(jq -r '.message // "fetch failed"' <<<"$data")
    jq -nc --arg m "$msg" '{text: "steam: error", tooltip: $m, class: "critical"}'
    exit 0
fi

jq -c '
    .summary as $s |
    {
        text: "\($s.total_games) games",
        tooltip: "\($s.great_count) great · \($s.playable_count) playable · \($s.anticheat_blocked_count) anti-cheat · \($s.borked_count) borked · \($s.checking_count) checking…",
        class: "low"
    }
' <<<"$data"
