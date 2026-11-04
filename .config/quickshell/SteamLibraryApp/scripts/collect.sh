#!/usr/bin/env bash
#
# Steam library + ProtonDB data source for the Quickshell dropdown panel
# (SteamLibraryWindow.qml) and the bar.luau summary capsule.
#
# Owned-games list comes from Steam's own Web API (GetOwnedGames) -- no
# dev-approval required, just a personal key from
# https://steamcommunity.com/dev/apikey. The key + SteamID64 are entered via
# the panel's own setup form (SteamLibraryWindow.qml) and stored encrypted
# at rest in the freedesktop Secret Service (gnome-keyring) by
# save-credentials.sh -- read back here with secret-tool, never plaintext
# on disk.
#
# ProtonDB tiers, native-Linux/Deck-category metadata, and the anti-cheat
# dataset are each refreshed in the background by their own self-locked
# worker (refresh-protondb.sh / refresh-metadata.sh) so opening the panel is
# never blocked on hundreds of individual lookups -- this script always
# returns immediately with whatever's cached, plus a "checking" count for
# tiers not looked up yet.
#
# Pass --force to bypass the owned-games cache and refetch from Steam now.

set -uo pipefail

SERVICE="steam-library-widget"
CACHE_DIR="$HOME/.cache/steam-library"
GAMES_FILE="$CACHE_DIR/games.json"
TIERS_FILE="$CACHE_DIR/protondb.json"
METADATA_FILE="$CACHE_DIR/metadata.json"
ANTICHEAT_FILE="$CACHE_DIR/anticheat-dataset.json"
GAMES_TTL=21600   # 6h -- a library barely changes minute to minute
FORCE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# "Installed" is local-client state, not part of the Steam Web API -- Valve's
# own libraryfolders.vdf (one per Steam library disk/mount) lists every
# installed appid directly under each library's "apps" block, which is
# cheaper and more reliable than globbing steamapps/appmanifest_*.acf across
# however many library folders exist. A line there looks like
# `"<appid>"   "<size-in-bytes>"` -- both quoted and purely numeric, which is
# what distinguishes it from the surrounding metadata keys (contentid,
# totalsize, etc.) that aren't purely-numeric keys.
STEAM_VDF_CANDIDATES=(
    "$HOME/.local/share/Steam/config/libraryfolders.vdf"
    "$HOME/.steam/steam/config/libraryfolders.vdf"
    "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/config/libraryfolders.vdf"
)
INSTALLED_JSON=$(grep -ohP '^\s*"\K[0-9]+(?="\s+"[0-9]+"\s*$)' "${STEAM_VDF_CANDIDATES[@]}" 2>/dev/null \
    | sort -un | jq -R -s 'split("\n") | map(select(length > 0))')

mkdir -p "$CACHE_DIR"

unconfigured() {
    jq -nc --arg msg "$1" '{configured:false, reason:"missing_credentials", message:$msg, last_updated:0, checking:0, games:[]}'
    exit 0
}

fetch_failed() {
    jq -nc --arg msg "$1" '{configured:true, reason:"fetch_failed", message:$msg, last_updated:0, checking:0, games:[]}'
    exit 0
}

command -v jq >/dev/null 2>&1 || unconfigured "jq is not installed"
command -v secret-tool >/dev/null 2>&1 || unconfigured "secret-tool not installed (pacman -S libsecret)"

STEAM_API_KEY=$(secret-tool lookup service "$SERVICE" key steam-api-key 2>/dev/null)
STEAM_ID64=$(secret-tool lookup service "$SERVICE" key steam-id64 2>/dev/null)
[ -n "$STEAM_API_KEY" ] && [ -n "$STEAM_ID64" ] || \
    unconfigured "Steam API key / SteamID64 not set up yet"

refresh_games() {
    local resp
    resp=$(curl -fsS --max-time 10 --proto '=https' --tlsv1.2 \
        "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=${STEAM_API_KEY}&steamid=${STEAM_ID64}&format=json&include_appinfo=true&include_played_free_games=true" \
        2>/dev/null)
    [ -n "$resp" ] || return 1
    jq -e '.response.games' >/dev/null 2>&1 <<<"$resp" || return 1

    jq '[.response.games[] | {
        appid: .appid,
        name: .name,
        playtime_forever: .playtime_forever,
        playtime_2weeks: (.playtime_2weeks // 0),
        icon_url: (if .img_icon_url != "" and .img_icon_url != null
            then "https://media.steampowered.com/steamcommunity/public/images/apps/\(.appid)/\(.img_icon_url).jpg"
            else "" end),
        cover_url: "https://cdn.akamai.steamstatic.com/steam/apps/\(.appid)/library_600x900.jpg"
    }]' <<<"$resp" > "$GAMES_FILE.tmp" && mv "$GAMES_FILE.tmp" "$GAMES_FILE"
}

stale=true
if [ -f "$GAMES_FILE" ] && [ "$FORCE" != "--force" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$GAMES_FILE") ))
    [ "$age" -lt "$GAMES_TTL" ] && stale=false
fi

if [ "$stale" = true ]; then
    refresh_games || {
        [ -f "$GAMES_FILE" ] || fetch_failed "Steam API request failed (bad key/id, private profile, or network)"
        # fetch failed but we have an older cache -- serve it rather than erroring
    }
fi

[ -f "$TIERS_FILE" ] || echo '{}' > "$TIERS_FILE"
[ -f "$METADATA_FILE" ] || echo '{}' > "$METADATA_FILE"
# Backdate the placeholder's mtime so refresh-metadata.sh's TTL check (which
# looks at file age, not content) sees it as stale and fetches the real
# dataset on the very next run, instead of treating "just created empty" as
# "freshly refreshed".
[ -f "$ANTICHEAT_FILE" ] || { echo '[]' > "$ANTICHEAT_FILE"; touch -d @0 "$ANTICHEAT_FILE"; }

# Kick the background refreshers; each self-locks so repeated calls are safe.
nohup "$SCRIPT_DIR/refresh-protondb.sh" >/dev/null 2>&1 &
disown
nohup "$SCRIPT_DIR/refresh-metadata.sh" >/dev/null 2>&1 &
disown

jq -n \
    --slurpfile games "$GAMES_FILE" \
    --slurpfile tiers "$TIERS_FILE" \
    --slurpfile meta "$METADATA_FILE" \
    --slurpfile anticheat "$ANTICHEAT_FILE" \
    --argjson installed_ids "$INSTALLED_JSON" \
    --argjson last_updated "$(stat -c %Y "$GAMES_FILE")" \
    '
    ($tiers[0] // {}) as $t |
    ($meta[0] // {}) as $m |
    # AreWeAntiCheatYet entries carry the Steam appid as a string in
    # storeIds.steam -- build a quick appid -> status lookup once.
    (($anticheat[0] // []) | map(select(.storeIds.steam != null)) |
        map({(.storeIds.steam): .status}) | add // {}) as $ac |
    ($installed_ids | map({(.): true}) | add // {}) as $installed |
    ($games[0] // []) as $g |
    ($g | map(
        ((.appid | tostring) as $id |
        (.tier // ($t[$id].tier // "unknown")) as $tier |
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
            installed: ($installed[$id] // false)
        })
    )) as $merged |
    {
        configured: true,
        last_updated: $last_updated,
        checking: ([$merged[] | select(.tier == "unknown")] | length),
        games: $merged,
        summary: {
            total_games: ($merged | length),
            total_playtime_minutes: ([$merged[].playtime_forever] | add // 0),
            native_linux_count: ([$merged[] | select(.native_linux == true)] | length),
            deck_verified_count: ([$merged[] | select(.deck_category == 3)] | length),
            installed_count: ([$merged[] | select(.installed == true)] | length),
            recently_played_count: ([$merged[] | select(.playtime_2weeks > 0)] | length),
            great_count: ([$merged[] | select(.category == "great")] | length),
            playable_count: ([$merged[] | select(.category == "playable")] | length),
            anticheat_blocked_count: ([$merged[] | select(.category == "anticheat_blocked")] | length),
            borked_count: ([$merged[] | select(.category == "borked")] | length),
            checking_count: ([$merged[] | select(.category == "checking")] | length)
        }
    }
    '
