#!/usr/bin/env bash
#
# Steam wishlist + ProtonDB/Deck/anti-cheat/native-Linux cross-reference --
# the same playability signals collect.sh computes for owned games, applied
# to games you don't own yet, to answer "which of these would actually run
# well before I buy them." Same credentials, same tier/metadata/anti-cheat
# caches as collect.sh (refresh-protondb.sh / refresh-metadata.sh already
# pull appids from both games.json and wishlist.json).
#
# IWishlistService/GetWishlist/v1 needs only the same personal Web API key
# used everywhere else here -- confirmed live against this account despite
# some documentation suggesting an OAuth access_token is required instead;
# a plain key works fine against your own public wishlist.
#
# Pass --force to bypass the wishlist cache and refetch from Steam now.

set -uo pipefail

SERVICE="steam-library-widget"
CACHE_DIR="$HOME/.cache/steam-library"
WISHLIST_FILE="$CACHE_DIR/wishlist.json"
TIERS_FILE="$CACHE_DIR/protondb.json"
METADATA_FILE="$CACHE_DIR/metadata.json"
ANTICHEAT_FILE="$CACHE_DIR/anticheat-dataset.json"
WISHLIST_TTL=43200   # 12h -- a wishlist changes less often than a library
FORCE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$CACHE_DIR"

unconfigured() {
    jq -nc --arg msg "$1" '{configured:false, reason:"missing_credentials", message:$msg, checking:0, games:[]}'
    exit 0
}

fetch_failed() {
    jq -nc --arg msg "$1" '{configured:true, reason:"fetch_failed", message:$msg, checking:0, games:[]}'
    exit 0
}

command -v jq >/dev/null 2>&1 || unconfigured "jq is not installed"
command -v secret-tool >/dev/null 2>&1 || unconfigured "secret-tool not installed (pacman -S libsecret)"

STEAM_API_KEY=$(secret-tool lookup service "$SERVICE" key steam-api-key 2>/dev/null)
STEAM_ID64=$(secret-tool lookup service "$SERVICE" key steam-id64 2>/dev/null)
[ -n "$STEAM_API_KEY" ] && [ -n "$STEAM_ID64" ] || \
    unconfigured "Steam API key / SteamID64 not set up yet"

refresh_wishlist() {
    local resp
    resp=$(curl -fsS --max-time 10 --proto '=https' --tlsv1.2 \
        "https://api.steampowered.com/IWishlistService/GetWishlist/v1/?steamid=${STEAM_ID64}&key=${STEAM_API_KEY}" \
        2>/dev/null)
    [ -n "$resp" ] || return 1
    jq -e '.response.items' >/dev/null 2>&1 <<<"$resp" || return 1

    jq '[.response.items[] | {
        appid: .appid,
        priority: .priority,
        date_added: .date_added,
        cover_url: "https://cdn.akamai.steamstatic.com/steam/apps/\(.appid)/library_600x900.jpg"
    }]' <<<"$resp" > "$WISHLIST_FILE.tmp" && mv "$WISHLIST_FILE.tmp" "$WISHLIST_FILE"
}

stale=true
if [ -f "$WISHLIST_FILE" ] && [ "$FORCE" != "--force" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$WISHLIST_FILE") ))
    [ "$age" -lt "$WISHLIST_TTL" ] && stale=false
fi

if [ "$stale" = true ]; then
    refresh_wishlist || {
        [ -f "$WISHLIST_FILE" ] || fetch_failed "Steam wishlist request failed (private profile or network)"
        # fetch failed but we have an older cache -- serve it rather than erroring
    }
fi

[ -f "$TIERS_FILE" ] || echo '{}' > "$TIERS_FILE"
[ -f "$METADATA_FILE" ] || echo '{}' > "$METADATA_FILE"
[ -f "$ANTICHEAT_FILE" ] || { echo '[]' > "$ANTICHEAT_FILE"; touch -d @0 "$ANTICHEAT_FILE"; }

# Kick the background refreshers; each self-locks so repeated calls (from
# collect.sh too) are safe -- they already cover wishlist.json's appids.
nohup "$SCRIPT_DIR/refresh-protondb.sh" >/dev/null 2>&1 &
disown
nohup "$SCRIPT_DIR/refresh-metadata.sh" >/dev/null 2>&1 &
disown

jq -n \
    --slurpfile wishlist "$WISHLIST_FILE" \
    --slurpfile tiers "$TIERS_FILE" \
    --slurpfile meta "$METADATA_FILE" \
    --slurpfile anticheat "$ANTICHEAT_FILE" \
    '
    ($tiers[0] // {}) as $t |
    ($meta[0] // {}) as $m |
    (($anticheat[0] // []) | map(select(.storeIds.steam != null)) |
        map({(.storeIds.steam): .status}) | add // {}) as $ac |
    ($wishlist[0] // []) as $w |
    ($w | map(
        ((.appid | tostring) as $id |
        ($t[$id].tier // "unknown") as $tier |
        ($ac[$id] // "") as $anticheat_status |
        (
            if $tier == "unknown" then "checking"
            elif ($anticheat_status == "Denied" or $anticheat_status == "Broken") then "anticheat_blocked"
            elif ($tier == "platinum" or $tier == "gold") then "great"
            elif ($tier == "silver" or $tier == "bronze") then "playable"
            else "borked"
            end
        ) as $category |
        (($m[$id].deck_category // 0)) as $deck_cat |
        . + {
            name: ($m[$id].name // ("App " + $id)),
            tier: $tier,
            tier_confidence: ($t[$id].confidence // ""),
            native_linux: ($m[$id].native_linux // false),
            deck_category: $deck_cat,
            deck_label: (
                if $deck_cat == 3 then "Verified"
                elif $deck_cat == 2 then "Playable"
                elif $deck_cat == 1 then "Unsupported"
                else "Unknown" end
            ),
            anticheat_status: $anticheat_status,
            category: $category,
            is_wishlist: true
        })
    )) as $merged |
    {
        configured: true,
        checking: ([$merged[] | select(.tier == "unknown")] | length),
        games: $merged,
        summary: {
            total_games: ($merged | length),
            native_linux_count: ([$merged[] | select(.native_linux == true)] | length),
            deck_verified_count: ([$merged[] | select(.deck_category == 3)] | length),
            great_count: ([$merged[] | select(.category == "great")] | length),
            playable_count: ([$merged[] | select(.category == "playable")] | length),
            anticheat_blocked_count: ([$merged[] | select(.category == "anticheat_blocked")] | length),
            borked_count: ([$merged[] | select(.category == "borked")] | length),
            checking_count: ([$merged[] | select(.category == "checking")] | length)
        }
    }
    '
