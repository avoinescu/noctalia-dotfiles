#!/usr/bin/env bash
# Shared logic for the Hellsing "Control Art Restriction System" theme.
# Sourced by both hellsing-scheduler.sh (the 5-minute poller) and
# hellsing-theme.sh (the instant on/off keybind) so they can never drift
# apart on what "applying a tier" actually means.
set -uo pipefail
# For play_theme_sound, used by hellsing_announce below -- needed by both
# callers (hellsing-theme.sh already sourced it separately;
# hellsing-scheduler.sh hadn't, so it lives here instead where both get it).
source "$(dirname "${BASH_SOURCE[0]}")/custom-theme-lib.sh"

HELLSING_TOGGLE="$HOME/.config/hypr/settings/hellsing-theme"
HELLSING_STATE="$HOME/.cache/ml4w/hellsing-tier"
HELLSING_WALLPAPER_DIR="$HOME/Pictures/wallpaper/hellsing"
NORMAL_LOGO="$HOME/.config/fastfetch/assets/alien.gif"
HELLSING_LOGO="$HOME/.config/fastfetch/assets/hellsing-seal.png"
FASTFETCH_CONFIGS=("$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config-zerotrust.jsonc")

mkdir -p "$(dirname "$HELLSING_STATE")"

set_fastfetch_logo() {
    local logo="$1"
    for f in "${FASTFETCH_CONFIGS[@]}"; do
        [ -f "$f" ] || continue
        sed -i "s#\"source\": \"[^\"]*fastfetch/assets/[^\"]*\"#\"source\": \"$logo\"#" "$f"
    done
    # fastfetch caches the rendered kitty-image payload by config path, not
    # by the source file's content/mtime.
    rm -rf "$HOME/.cache/fastfetch/images"
}

hellsing_tier_for_hour() {
    local h="$1"
    if   [ "$h" -ge 6 ]  && [ "$h" -lt 11 ]; then echo "seal"
    elif [ "$h" -ge 11 ] && [ "$h" -lt 17 ]; then echo "release-1"
    elif [ "$h" -ge 17 ] && [ "$h" -lt 21 ]; then echo "release-2"
    else echo "release-true"
    fi
}

HELLSING_SOUNDS="$HOME/.config/hypr/sounds/hellsing"

# Sounds are real Japanese-dub clips from Alucard's restriction-release scene
# (Hellsing Ultimate OVA 8): the "Control Art Restriction Systems 3-2-1"
# release line for both release tiers (that scene doesn't split cleanly into
# two separate moments, so the same clip fits both), and the "Bird of
# Hermes" full-power line for release-true. Seal is the restrained/normal
# state -- no release line fits it, so it stays notification-only, same
# principle as Proxima having no static-theme sound.
hellsing_announce() {
    case "$1" in
        seal)          notify-send -a "Hellsing" "Control Art Restriction System" "Seal engaged. Order Number One in effect." 2>/dev/null ;;
        release-1)     notify-send -a "Hellsing" "Restriction Level 1 Released" "\"Let's go to work.\"" 2>/dev/null
                       play_theme_sound "$HELLSING_SOUNDS/level-release.mp3" ;;
        release-2)     notify-send -a "Hellsing" "Restriction Level 2 Released" "The hounds are loose." 2>/dev/null
                       play_theme_sound "$HELLSING_SOUNDS/level-release.mp3" ;;
        release-true)  notify-send -a "Hellsing" "No Longer Human" "All restrictions lifted." 2>/dev/null
                       play_theme_sound "$HELLSING_SOUNDS/full-power.mp3" ;;
    esac
}

hellsing_apply_tier() {
    local tier="$1"

    stop_theme_sound   # from custom-theme-lib.sh; Seal has no sound of its own

    local wp
    wp=$(find "$HELLSING_WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n1)
    if [ -n "$wp" ]; then
        noctalia msg wallpaper-set "$wp" 2>/dev/null
        sleep 1   # let Noctalia render the new wallpaper before we reload theme-manager below
    fi

    noctalia msg color-scheme-set custom "hellsing-$tier" 2>/dev/null
    cp "$HOME/.config/ml4w/colors/hellsing/$tier.json" "$HOME/.config/ml4w/colors/colors.json"
    qs ipc call theme-manager reload 2>/dev/null || true

    cp "$HOME/.config/hypr/colors/hellsing/$tier.conf" "$HOME/.config/hypr/colors.conf"
    hyprctl reload 2>/dev/null || true

    set_fastfetch_logo "$HELLSING_LOGO"
    echo "$tier" > "$HELLSING_STATE"
}
