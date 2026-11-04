#!/usr/bin/env bash
#
# Compact bar text/tooltip for the book-alerts plugin's bar.luau capsule,
# derived from the same local cache file BookAlertsWindow.qml watches
# (~/.cache/book-alerts/shared-snapshot.json, synced down from Proton Drive
# by book-alerts-download.timer). Click opens the full panel instead.
#
# The badge count is deliberately NOT the snapshot's raw item count. That
# snapshot is a 14-day rolling window of everything n8n has flagged as
# new/restocked/price-changed -- it only grows (or plateaus), it never
# reflects whether you've already looked at it, so as a bar badge it just
# climbs forever. Instead this counts items changed since last-viewed.json's
# timestamp, which the panel touches (mark-viewed.sh) every time it's
# opened -- so the badge behaves like a normal unread count and clears back
# toward 0 once you've looked, only climbing again as genuinely new deltas
# land afterward.

set -uo pipefail

CACHE="$HOME/.cache/book-alerts/shared-snapshot.json"
LAST_VIEWED="$HOME/.cache/book-alerts/last-viewed.json"

if [ ! -f "$CACHE" ]; then
    printf '{"text": "books: --", "tooltip": "no snapshot yet", "class": "low"}\n'
    exit 0
fi

data=$(cat "$CACHE")

total=$(jq -r '.items | length' <<<"$data" 2>/dev/null)
if [ -z "$total" ] || [ "$total" = "null" ]; then
    printf '{"text": "books: error", "tooltip": "failed to parse snapshot", "class": "critical"}\n'
    exit 0
fi

lastViewedAt="1970-01-01T00:00:00Z"
if [ -f "$LAST_VIEWED" ]; then
    v=$(jq -r '.lastViewedAt // empty' "$LAST_VIEWED" 2>/dev/null)
    [ -n "$v" ] && lastViewedAt="$v"
fi

count=$(jq -r --arg since "$lastViewedAt" '[.items[]? | select(.changedAt > $since)] | length' <<<"$data")

hasRestock=$(jq -r --arg since "$lastViewedAt" '[.items[]? | select(.changedAt > $since) | select(.changeType=="restock" or .changeType=="restock_and_price_change")] | length > 0' <<<"$data")
hasPriceChange=$(jq -r --arg since "$lastViewedAt" '[.items[]? | select(.changedAt > $since) | select(.changeType=="price_change" or .changeType=="restock_and_price_change")] | length > 0' <<<"$data")
anySourceDown=$(jq -r '[.sources[]? | select(.ok==false)] | length > 0' <<<"$data")

class="low"
[ "$count" = "0" ] && class="low"
[ "$hasPriceChange" = "true" ] && class="mid"
[ "$hasRestock" = "true" ] && class="high"

extra=""
[ "$anySourceDown" = "true" ] && extra=" · a source is failing"

jq -nc --arg t "${count} alerts" --arg tip "${total} in the last 14 days · click for full Book Alerts panel${extra}" --arg c "$class" \
    '{text: $t, tooltip: $tip, class: $c}'
