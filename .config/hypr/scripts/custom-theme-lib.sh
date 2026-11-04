#!/usr/bin/env bash
# Shared apply/deactivate logic for the "static" (one-shot, non-scheduled)
# custom themes -- Joker, Illidan, Arthas, Blood Elves, Mortal Shell II
# (Proxima), Warframe, War Thunder. Each theme script is a thin wrapper
# around apply_static_theme/deactivate_static_theme below, sourcing this
# file the same way hellsing-scheduler.sh/hellsing-theme.sh share
# hellsing-lib.sh.
#
# A single "active static theme" file replaces the old pairwise preemption
# (Joker turning off Hellsing's toggle directly, and vice versa) -- that
# doesn't scale past two themes. Turning any static theme on deactivates
# whichever OTHER static theme (if any) was active, and neutralizes
# Hellsing's toggle the same way Joker always did, restoring it when this
# theme turns back off.
set -uo pipefail

ACTIVE_STATIC="$HOME/.cache/ml4w/active-static-theme"
HELLSING_TOGGLE="$HOME/.config/hypr/settings/hellsing-theme"
HELLSING_STATE="$HOME/.cache/ml4w/hellsing-tier"
HELLSING_PREV="$HOME/.cache/ml4w/static-prev-hellsing-toggle"
NORMAL_LOGO="$HOME/.config/fastfetch/assets/alien.gif"
FASTFETCH_CONFIGS=("$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config-zerotrust.jsonc")

mkdir -p "$(dirname "$ACTIVE_STATIC")"

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

# Usage: play_theme_sound <path-to-mp3-or-directory>
# Optional per-theme accompaniment for a notification (e.g. a real game
# voice line or a music snippet) -- no-ops silently if nothing's there,
# since most themes won't have one. A directory picks one *.mp3 at random
# each call (for themes with more than one fitting clip); a single file
# just plays that file. Backgrounded so the theme script doesn't block on
# playback.
#
# Only one theme sound plays at a time: the previous one (e.g. a 20s music
# snippet) is stopped first, see stop_theme_sound.
THEME_SOUND_PID="${XDG_RUNTIME_DIR:-/tmp}/theme-sound.pid"

# Stops the currently playing theme sound, if any. Called at the very start
# of every theme switch (not just when the next sound starts) so the old clip
# cuts out the moment you pick a theme -- including themes with no sound of
# their own. Only kills the PID if it's still actually our paplay, so a stale
# pidfile whose PID got recycled can never hit an unrelated process.
stop_theme_sound() {
    [ -f "$THEME_SOUND_PID" ] || return 0
    local pid
    pid="$(cat "$THEME_SOUND_PID" 2>/dev/null)"
    if [ -n "$pid" ] && [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = "paplay" ]; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$THEME_SOUND_PID"
}

play_theme_sound() {
    local sound="$1" pick=""
    if [ -d "$sound" ]; then
        pick="$(find "$sound" -maxdepth 1 -type f -iname '*.mp3' | shuf -n1)"
    elif [ -f "$sound" ]; then
        pick="$sound"
    fi
    [ -n "$pick" ] || return 0
    stop_theme_sound
    paplay "$pick" >/dev/null 2>&1 &
    echo $! > "$THEME_SOUND_PID"
    disown
}

# Silently clears the "active static theme" bookkeeping with no
# notification and no Hellsing restore -- used only for a direct handoff to
# a DIFFERENT theme (static-to-static, or static-to-Hellsing), where the
# outgoing theme isn't really being "turned off", it's being immediately
# replaced. Calling the outgoing theme's own public off-path there (as this
# used to) fired its off-quote AND restored+reapplied+announced Hellsing
# only for the incoming theme to immediately re-preempt it a moment later --
# a spurious detour through Hellsing on every theme-to-theme switch.
_clear_active_static() {
    rm -f "$ACTIVE_STATIC"
}

# Turns off whatever else is active (another static theme, or Hellsing)
# before applying a new one -- so no two custom themes can fight over the
# same fastfetch logo / ml4w colors.json / Hyprland colors.conf.
_deactivate_others() {
    local mine="$1"
    local other=""
    [ -f "$ACTIVE_STATIC" ] && other="$(cat "$ACTIVE_STATIC")"
    if [ -n "$other" ] && [ "$other" != "$mine" ]; then
        _clear_active_static
    fi

    # Snapshot Hellsing's ambient toggle state ONLY when starting a fresh
    # "chain" from no static theme being active ($other empty) -- unconditionally,
    # even if it's already "off", overwriting any stale leftover from a
    # previous chain. A later theme in the same chain (direct handoff, $other
    # non-empty) must NOT re-snapshot: HELLSING_TOGGLE has already been
    # forced "off" by the first theme, and re-snapshotting here would record
    # that "off" as if it were the true ambient state, permanently losing
    # what to restore when the chain's last theme genuinely turns off.
    if [ -z "$other" ]; then
        local current_toggle="off"
        [ -f "$HELLSING_TOGGLE" ] && current_toggle="$(cat "$HELLSING_TOGGLE")"
        echo "$current_toggle" > "$HELLSING_PREV"
    fi
    echo "off" > "$HELLSING_TOGGLE"
    echo "off" > "$HELLSING_STATE"
}

# Restores Hellsing's toggle to whatever it was before this theme preempted
# it. If that means Hellsing goes back to "on", also reapplies its current
# tier immediately -- otherwise the desktop would keep showing this theme's
# colors for up to 5 minutes until hellsing-scheduler.sh's next poll.
_restore_hellsing() {
    if [ -f "$HELLSING_PREV" ]; then
        cp "$HELLSING_PREV" "$HELLSING_TOGGLE"
        rm -f "$HELLSING_PREV"
        if [ "$(cat "$HELLSING_TOGGLE")" = "on" ]; then
            "$(dirname "${BASH_SOURCE[0]}")/hellsing-theme.sh" on
        fi
    fi
}

# Usage: apply_static_theme <id> <wallpaper_dir> <colors_json> <colors_conf> <logo>
apply_static_theme() {
    local id="$1" wallpaper_dir="$2" colors_json="$3" colors_conf="$4" logo="$5"

    stop_theme_sound
    _deactivate_others "$id"

    # Written BEFORE wallpaper-set (not just at the end) so
    # noctalia-theme-quickshell.sh's wallpaper_changed hook can see a static
    # theme is applying and skip its own Matugen pass -- otherwise that hook
    # races us: it recolors Quickshell from the raw photo (a generic,
    # unrelated-looking palette) a moment before our own colors.json below
    # overwrites it, visible as a brief "wrong" flash.
    echo "$id" > "$ACTIVE_STATIC"

    local wp
    wp=$(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n1)
    if [ -n "$wp" ]; then
        noctalia msg wallpaper-set "$wp" 2>/dev/null
        sleep 1   # let Noctalia render the new wallpaper before we reload theme-manager below
    fi

    noctalia msg color-scheme-set custom "$id" 2>/dev/null
    cp "$colors_json" "$HOME/.config/ml4w/colors/colors.json"
    qs ipc call theme-manager reload 2>/dev/null || true

    cp "$colors_conf" "$HOME/.config/hypr/colors.conf"
    hyprctl reload 2>/dev/null || true

    set_fastfetch_logo "$logo"
}

# Usage: deactivate_static_theme <id>
# No-ops (other than the Hellsing-restore/logo-reset) if <id> wasn't the
# active one -- safe to call unconditionally.
deactivate_static_theme() {
    local id="$1"
    stop_theme_sound
    if [ -f "$ACTIVE_STATIC" ] && [ "$(cat "$ACTIVE_STATIC")" = "$id" ]; then
        rm -f "$ACTIVE_STATIC"
    fi
    _restore_hellsing
    set_fastfetch_logo "$NORMAL_LOGO"
}

# For Hellsing's own "on" path (hellsing-theme.sh) to call, so turning
# Hellsing on preempts whichever static theme is active without Hellsing
# needing to know any of their names. Silent, like _deactivate_others --
# Hellsing turning on is itself the "restore", so the outgoing theme's
# off-quote/Hellsing-restore dance would be redundant (and previously caused
# a duplicate tier announcement via re-entrant hellsing-theme.sh calls).
deactivate_active_static_theme() {
    [ -f "$ACTIVE_STATIC" ] && _clear_active_static
}
