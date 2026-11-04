#!/usr/bin/env bash
#
# Compact bar text/tooltip for the ai-usage plugin's bar.luau capsule,
# derived from collect.sh's output (same data the Quickshell dropdown panel
# shows in full). Shows Claude Code's session/weekly % since that's the
# provider with real data today; click opens the full panel instead.
#
# Consumed by ~/.local/share/noctalia/plugins/ai-usage/service.luau.

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data=$("$DIR/collect.sh")

primary=$(jq -c '.providers[] | select(.id=="claude-code")' <<<"$data")
if [ -z "$primary" ]; then
    printf '{"text": "ai: n/a", "tooltip": "no providers configured", "class": "critical"}\n'
    exit 0
fi

available=$(jq -r '.available' <<<"$primary")
if [ "$available" != "true" ]; then
    msg=$(jq -r '.message // "unavailable"' <<<"$primary")
    printf '{"text": "claude: --", "tooltip": "%s", "class": "critical"}\n' "$msg"
    exit 0
fi

session=$(jq -r '.limits[] | select(.label=="Session") | .percent' <<<"$primary")
weekly=$(jq -r '.limits[] | select(.label=="Weekly") | .percent' <<<"$primary")

worst=$session
[ "$weekly" -gt "$worst" ] && worst=$weekly

class="low"
[ "$worst" -ge 50 ] && class="mid"
[ "$worst" -ge 75 ] && class="high"
[ "$worst" -ge 90 ] && class="critical"

jq -nc --arg t "${session}% · ${weekly}%" --arg c "$class" \
    '{text: $t, tooltip: "Click for full AI usage panel", class: $c}'
