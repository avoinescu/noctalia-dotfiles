#!/usr/bin/env bash
#
# On-demand (not bulk-background) achievement lookup for one game, called by
# the big-picture panel when a game card is selected. Unlike ProtonDB/deck
# metadata, achievements need 2 API calls per game (schema + player progress)
# so doing this for the whole library up front would be hundreds of extra
# requests on every refresh -- fetching lazily per-click keeps it cheap.
#
# Usage: achievements-fetch.sh <appid>
# Output: {available, unlocked, total, achievements:[{name,icon,achieved}]}
# -- available is false for games with no achievement schema, or when the
# profile/game stats are private (GetPlayerAchievements success=false). Each
# achievement's icon is already the right one for its current state (the
# schema gives separate unlocked/locked icon URLs).

set -uo pipefail

SERVICE="steam-library-widget"
CACHE_DIR="$HOME/.cache/steam-library/achievements"
TTL=3600
APPID="${1:-}"

unavailable() {
    jq -nc '{available:false, unlocked:0, total:0, achievements:[]}'
    exit 0
}

[ -n "$APPID" ] || unavailable
command -v jq >/dev/null 2>&1 || unavailable
command -v secret-tool >/dev/null 2>&1 || unavailable

mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/${APPID}.json"

if [ -f "$CACHE_FILE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if [ "$age" -lt "$TTL" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

STEAM_API_KEY=$(secret-tool lookup service "$SERVICE" key steam-api-key 2>/dev/null)
STEAM_ID64=$(secret-tool lookup service "$SERVICE" key steam-id64 2>/dev/null)
[ -n "$STEAM_API_KEY" ] && [ -n "$STEAM_ID64" ] || unavailable

schema=$(curl -fsS --max-time 8 \
    "https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v0002/?key=${STEAM_API_KEY}&appid=${APPID}&format=json" 2>/dev/null)
[ -n "$schema" ] || unavailable
jq -e '.game.availableGameStats.achievements | length > 0' >/dev/null 2>&1 <<<"$schema" || unavailable

progress=$(curl -fsS --max-time 8 \
    "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?key=${STEAM_API_KEY}&steamid=${STEAM_ID64}&appid=${APPID}&format=json" 2>/dev/null)
[ -n "$progress" ] || unavailable
success=$(jq -r '.playerstats.success // false' <<<"$progress" 2>/dev/null)
[ "$success" = "true" ] || unavailable

tmp=$(mktemp "$CACHE_FILE.XXXXXX")
jq -nc --argjson schema "$schema" --argjson progress "$progress" '
    ($progress.playerstats.achievements // [] | map({(.apiname): (.achieved == 1)}) | add // {}) as $achieved |
    ($schema.game.availableGameStats.achievements // []) as $defs |
    ($defs | map({
        name: (.displayName // .name),
        achieved: ($achieved[.name] // false),
        icon: (if ($achieved[.name] // false) then .icon else (.icongray // .icon) end)
    })) as $list |
    {
        available: true,
        unlocked: ([$list[] | select(.achieved)] | length),
        total: ($list | length),
        achievements: $list
    }
' > "$tmp" && mv "$tmp" "$CACHE_FILE"
cat "$CACHE_FILE"
