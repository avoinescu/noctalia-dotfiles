#!/usr/bin/env bash
# Static "Paul Atreides -- Muad'Dib" theme (Dune) -- spice/desert amber,
# deep stillsuit-night blue, the blue-within-blue Ibad eyes, on a
# near-black desert-night background. One-shot apply/revert, not a
# poller. Shared apply/deactivate logic (including cross-theme
# preemption) lives in custom-theme-lib.sh, used by every static custom
# theme.
#
# The on-quote is the opening of the Bene Gesserit "Litany Against Fear"
# Paul recites (Frank Herbert's Dune) -- verified verbatim against
# multiple independent sources (Goodreads, the Dune Fandom wiki, and a
# dedicated Frank Herbert poems archive), which all agree on the exact
# wording: "I must not fear. Fear is the mind-killer. Fear is the
# little-death that brings total obliteration."
#
# The on-notification also plays sounds/atreides.mp3 -- "I must not
# fear," Paul's real line from a Dune (2021) film-scene compilation on
# YouTube, trimmed using that video's own auto-generated captions to find
# the exact timestamp (the surrounding trailer VO overlaps other dialogue
# immediately before/after, so the caption boundary was used rather than
# guessing by ear), then verified non-silent/non-clipping with ffmpeg
# volumedetect (mean -15.7dB, max -0.2dB). The fastfetch logo is a
# "Children of Dune" book-cover render (pngegg.com was returning 500s at
# sourcing time; hiclipart.com's checkerboard-preview was keyed to real
# alpha with ImageMagick instead) rather than a character portrait, since
# no clean in-character Paul Atreides clipart turned up. The off-quote is
# flavor text, not a real line -- deliberately not "the spice must flow,"
# which is real but from the 1984 film's Guild Navigator/Baron dialogue,
# not Paul's own.
#
# Usage: atreides-theme.sh [on|off]   (no arg = toggle based on current state)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

ID="atreides"
WALLPAPER_DIR="$HOME/Pictures/wallpaper/atreides"
COLORS_JSON="$HOME/.config/ml4w/colors/atreides.json"
COLORS_CONF="$HOME/.config/hypr/colors/atreides.conf"
LOGO="$HOME/.config/fastfetch/assets/atreides-face.png"
SOUND="$HOME/.config/hypr/sounds/atreides.mp3"

CURRENT="off"
[ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$ID" ] && CURRENT="on"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ "$CURRENT" = "off" ] && TARGET="on" || TARGET="off"
fi

if [ "$TARGET" = "on" ]; then
    apply_static_theme "$ID" "$WALLPAPER_DIR" "$COLORS_JSON" "$COLORS_CONF" "$LOGO"
    notify-send -a "Paul Atreides" "I must not fear. Fear is the mind-killer. Fear is the little-death that brings total obliteration." 2>/dev/null || true
    play_theme_sound "$SOUND"
else
    deactivate_static_theme "$ID"
    notify-send -a "Paul Atreides" "The desert fades. Only the vision remains." 2>/dev/null || true
fi
