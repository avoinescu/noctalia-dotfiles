#!/usr/bin/env bash
# Static "Khorne" theme (Warhammer 40,000 / Warhammer Fantasy) -- the Chaos
# God of Blood and War: blood-red dominant, brass/bronze skull-throne
# accents, on near-black. One-shot apply/revert, not a poller. Shared
# apply/deactivate logic (including cross-theme preemption) lives in
# custom-theme-lib.sh, used by every static custom theme.
#
# Quotes verified via web search, not memory: "Blood for the Blood God!
# Skulls for the Skull Throne!" is Khorne's real recurring in-lore war cry
# (Lexicanum/Warhammer 40k Wiki); "Khorne cares not from whence the blood
# flows, only that it flows" is a real, widely-cited lore line describing
# his indifference to whose blood is spilled.
#
# The on-notification also plays a random clip from sounds/khorne/ -- real
# "Blood for the Blood God" clips from Warhammer games, sourced from
# myinstants.com. One of the three (blood-for-the-blood-god-1.mp3) is
# actually a Chaos-worshipper speech (Azariah Kyras, Vermintide 2's Chaos
# Wastes) rather than the chant itself -- kept in the pool since it's real
# Warhammer Chaos dialogue and was tagged by its uploader as this exact
# quote, but worth a listen if you want to prune it.
#
# Logo: pngegg's search was unreachable/returned no relevant results for
# "khorne"/"warhammer" (Cloudflare-blocked), so the logo is a generated
# stylized 8-pointed Khorne rune (ImageMagick) rather than sourced fan art
# -- fine visually but a deviation from every other theme's sourced-art
# logo, worth swapping for real art later if found.
#
# Usage: khorne-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="khorne"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/khorne"
COLORS_JSON="$HOME/.config/ml4w/colors/khorne.json"
COLORS_CONF="$HOME/.config/hypr/colors/khorne.conf"
LOGO="$HOME/.config/fastfetch/assets/khorne-face.png"
SOUND="$HOME/.config/hypr/sounds/khorne"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Khorne" "Blood for the Blood God! Skulls for the Skull Throne!" 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Khorne" "Khorne cares not from whence the blood flows, only that it flows." 2>/dev/null || true
fi
