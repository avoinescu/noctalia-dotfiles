#!/usr/bin/env bash
#
# Background worker: fills in missing/stale ProtonDB tiers for the Steam
# library widget. Designed to be fired-and-forgotten by collect.sh -- it
# writes into CACHE_FILE incrementally (one flush per game) so a poll or
# panel-open shortly after still shows partial progress instead of nothing.
#
# ProtonDB has no documented public rate limit, but this is someone else's
# free service -- SLEEP_SECS between requests keeps it polite rather than
# hammering it on a fresh library import (hundreds of games).
#
# Appids come from both games.json (owned) and wishlist.json (not owned) --
# wishlist-collect.sh reuses this same tier cache to answer "which of these
# would actually run well before I buy them."

set -uo pipefail

CACHE_DIR="$HOME/.cache/steam-library"
GAMES_FILE="$CACHE_DIR/games.json"
WISHLIST_FILE="$CACHE_DIR/wishlist.json"
CACHE_FILE="$CACHE_DIR/protondb.json"
LOCK_FILE="$CACHE_DIR/refresh.lock"
TIER_TTL=$(( 14 * 86400 ))   # ratings drift slowly -- 14 days
FAIL_TTL=3600                # retry failed/pending lookups sooner
SLEEP_SECS=0.3

mkdir -p "$CACHE_DIR"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0   # another refresh is already running, don't stack

[ -f "$GAMES_FILE" ] || [ -f "$WISHLIST_FILE" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

[ -f "$CACHE_FILE" ] || echo '{}' > "$CACHE_FILE"

now=$(date +%s)

mapfile -t appids < <(jq -r '.[].appid' "$GAMES_FILE" "$WISHLIST_FILE" 2>/dev/null | sort -un)

for appid in "${appids[@]}"; do
    checked_at=$(jq -r --arg id "$appid" '.[$id].checked_at // 0' "$CACHE_FILE")
    tier=$(jq -r --arg id "$appid" '.[$id].tier // "unknown"' "$CACHE_FILE")
    ttl=$TIER_TTL
    if [ "$tier" = "unknown" ] || [ "$tier" = "pending" ]; then
        ttl=$FAIL_TTL
    fi
    age=$(( now - checked_at ))
    [ "$age" -lt "$ttl" ] && continue

    resp=$(curl -fsS --max-time 8 "https://www.protondb.com/api/v1/reports/summaries/${appid}.json" 2>/dev/null)
    if [ -n "$resp" ] && jq -e . >/dev/null 2>&1 <<<"$resp"; then
        tier=$(jq -r '.tier // "pending"' <<<"$resp")
        confidence=$(jq -r '.confidence // ""' <<<"$resp")
    else
        tier="unknown"
        confidence=""
    fi

    tmp=$(mktemp "$CACHE_FILE.XXXXXX")
    jq --arg id "$appid" --arg tier "$tier" --arg conf "$confidence" --argjson ts "$now" \
        '.[$id] = {tier:$tier, confidence:$conf, checked_at:$ts}' \
        "$CACHE_FILE" > "$tmp" && mv "$tmp" "$CACHE_FILE"

    sleep "$SLEEP_SECS"
done
