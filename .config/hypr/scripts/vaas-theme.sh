#!/usr/bin/env bash
# Static "Vaas Montenegro" (Far Cry 3) theme -- jungle green/blood-red/tribal
# orange on near-black, deliberately NOT scheduled/evolving like the Hellsing
# theme. One-shot apply/revert, not a poller. Shared apply/deactivate logic
# (including cross-theme preemption) lives in custom-theme-lib.sh, used by
# every static custom theme.
#
# Both notification quotes are real, verbatim lines from Vaas's famous
# "definition of insanity" monologue (verified via a quotes.net game-dialogue
# transcript). The on-notification also plays
# sounds/vaas/definition-of-insanity.mp3 -- the full ~34s monologue, sourced
# from myinstants.com.
#
# Usage: vaas-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="vaas"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/vaas"
COLORS_JSON="$HOME/.config/ml4w/colors/vaas.json"
COLORS_CONF="$HOME/.config/hypr/colors/vaas.conf"
LOGO="$HOME/.config/fastfetch/assets/vaas-face.png"
SOUND="$HOME/.config/hypr/sounds/vaas"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Vaas Montenegro" "Did I ever tell you what the definition of insanity is?" "Insanity is doing the exact same fucking thing, over and over again, expecting shit to change." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Vaas Montenegro" "That. Is. Crazy." 2>/dev/null || true
fi
