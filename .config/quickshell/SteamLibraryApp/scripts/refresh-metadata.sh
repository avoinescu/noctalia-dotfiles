#!/usr/bin/env bash
#
# Background worker: fills in per-game native-Linux support + Steam Deck
# compatibility category, and refreshes the "Are We Anti-Cheat Yet" dataset
# used to flag anti-cheat-blocked games. Same fire-and-forget model as
# refresh-protondb.sh (self-locked, incremental writes, own lock file so the
# two workers run independently of each other).
#
# Both per-game endpoints used here are undocumented (store.steampowered.com
# internal APIs, not the official Web API) but stable in practice:
#   - appdetails?filters=basic,platforms tells us the display name (needed
#     for wishlist entries, which the Wishlist API doesn't return a name
#     for) and platforms.linux (native support), in the same request.
#   - ajaxgetdeckappcompatibilityreport tells us Valve's own Deck category
#     (0=unknown, 1=unsupported, 2=playable, 3=verified).
# The anti-cheat dataset is a single fetch regardless of library size --
# collect.sh does the per-game appid lookup itself, no per-game network call
# needed for that one.
#
# Appids come from both games.json (owned) and wishlist.json (not owned) --
# wishlist-collect.sh needs the same native-Linux/Deck signals as the owned
# library to answer "which of these would actually run well".

set -uo pipefail

CACHE_DIR="$HOME/.cache/steam-library"
GAMES_FILE="$CACHE_DIR/games.json"
WISHLIST_FILE="$CACHE_DIR/wishlist.json"
CACHE_FILE="$CACHE_DIR/metadata.json"
ANTICHEAT_FILE="$CACHE_DIR/anticheat-dataset.json"
LOCK_FILE="$CACHE_DIR/metadata-refresh.lock"
META_TTL=$(( 30 * 86400 ))     # platform/Deck category changes rarely
FAIL_TTL=3600
ANTICHEAT_TTL=$(( 86400 ))     # dataset itself is refreshed daily
SLEEP_SECS=0.3

mkdir -p "$CACHE_DIR"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

command -v jq >/dev/null 2>&1 || exit 0

# --- Anti-cheat dataset (one fetch, not per-game) ---
if [ ! -f "$ANTICHEAT_FILE" ] || [ $(( $(date +%s) - $(stat -c %Y "$ANTICHEAT_FILE" 2>/dev/null || echo 0) )) -ge "$ANTICHEAT_TTL" ]; then
    resp=$(curl -fsS --max-time 15 \
        "https://raw.githubusercontent.com/AreWeAntiCheatYet/AreWeAntiCheatYet/HEAD/games.json" 2>/dev/null)
    if [ -n "$resp" ] && jq -e . >/dev/null 2>&1 <<<"$resp"; then
        printf '%s' "$resp" > "$ANTICHEAT_FILE"
    fi
fi

[ -f "$GAMES_FILE" ] || [ -f "$WISHLIST_FILE" ] || exit 0
[ -f "$CACHE_FILE" ] || echo '{}' > "$CACHE_FILE"

now=$(date +%s)
mapfile -t appids < <(jq -r '.[].appid' "$GAMES_FILE" "$WISHLIST_FILE" 2>/dev/null | sort -un)

for appid in "${appids[@]}"; do
    checked_at=$(jq -r --arg id "$appid" '.[$id].checked_at // 0' "$CACHE_FILE")
    known=$(jq -r --arg id "$appid" 'has($id)' "$CACHE_FILE")
    ttl=$META_TTL
    [ "$known" != "true" ] && ttl=$FAIL_TTL
    age=$(( now - checked_at ))
    [ "$age" -lt "$ttl" ] && continue

    native_linux=false
    deck_category=0
    name=$(jq -r --arg id "$appid" '.[$id].name // ""' "$CACHE_FILE")

    details=$(curl -fsS --max-time 8 \
        "https://store.steampowered.com/api/appdetails?appids=${appid}&filters=basic,platforms" 2>/dev/null)
    if [ -n "$details" ] && jq -e ".\"${appid}\".success" >/dev/null 2>&1 <<<"$details"; then
        native_linux=$(jq -r ".\"${appid}\".data.platforms.linux // false" <<<"$details")
        name=$(jq -r ".\"${appid}\".data.name // \"\"" <<<"$details")
    fi

    deck=$(curl -fsS --max-time 8 \
        "https://store.steampowered.com/saleaction/ajaxgetdeckappcompatibilityreport?nAppID=${appid}" 2>/dev/null)
    if [ -n "$deck" ] && jq -e . >/dev/null 2>&1 <<<"$deck"; then
        # .results is sometimes [] instead of an object (untested/delisted
        # apps) -- guard the type before indexing into it.
        deck_category=$(jq -r 'if (.results? | type) == "object" then (.results.resolved_category // 0) else 0 end' <<<"$deck" 2>/dev/null)
        [ -n "$deck_category" ] || deck_category=0
    fi

    tmp=$(mktemp "$CACHE_FILE.XXXXXX")
    jq --arg id "$appid" --arg name "$name" --argjson linux "$native_linux" --argjson deck "$deck_category" --argjson ts "$now" \
        '.[$id] = {name:$name, native_linux:$linux, deck_category:$deck, checked_at:$ts}' \
        "$CACHE_FILE" > "$tmp" && mv "$tmp" "$CACHE_FILE"

    sleep "$SLEEP_SECS"
done
