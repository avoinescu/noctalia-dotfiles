#!/usr/bin/env bash
# Replace SDDM with noctalia-greeter (a greetd greeter with its own bundled
# wlroots compositor) as the login screen. Arch/CachyOS only.
#
# Why: SDDM runs its greeter on X11, where the NVIDIA driver names ports
# differently from Hyprland (DP-0/DP-2 vs DP-1/DP-2), so the 34" ended up on
# the wrong side at login. noctalia-greeter is Wayland/DRM, uses the same
# connector names as Hyprland, takes an explicit layout, and can sync
# wallpaper + palette from Noctalia so the login screen matches the theme.
#
# Safe to run from inside a live session: it only enables/disables units, it
# does NOT stop SDDM (that would kill the running desktop). The switch takes
# effect on the next boot. SDDM stays installed as the fallback.
#
# ROLLBACK (e.g. greeter shows a black screen): Ctrl+Alt+F2, log in, then
#   sudo systemctl disable greetd && sudo systemctl enable sddm && sudo reboot
#
# Usage: ./setup-greeter.sh               full setup (prompts for sudo)
#        ./setup-greeter.sh --dry-run     print what would change
#        ./setup-greeter.sh --appearance  only re-apply the greeter.toml
#                                         settings below (look/layout), then
#                                         log out to see them
set -euo pipefail

DRY=0
APPEARANCE_ONLY=0
case "${1:-}" in
    --dry-run)    DRY=1 ;;
    --appearance) APPEARANCE_ONLY=1 ;;
esac

# --- Layout: keep in sync with .config/hypr/modules/monitors.lua -----------
LOGIN_OUTPUT="DP-1"                          # 32" -- shows the login form
LAYOUT="DP-1:0,0; DP-2:2560,0"               # 34" ultrawide to the right
REFRESH="DP-1:165; DP-2:144"
DEFAULT_SESSION="Hyprland"                   # Name= from /usr/share/wayland-sessions
# ---------------------------------------------------------------------------

# greeter.toml settings, one 'table|key|toml-value' each. These win over
# what Noctalia's Auto-Sync writes to sync.toml (wallpaper/palette/font still
# come from the sync). Options: noctalia-greeter docs/user/configuration.md.
# The greeter has no avatar / welcome text / weather widgets.
GREETER_SETTINGS=(
    "output|name|\"$LOGIN_OUTPUT\""
    "output|layout|\"$LAYOUT\""
    "output|refresh_rate|\"$REFRESH\""
    "session|default|\"$DEFAULT_SESSION\""
    "user|default|\"$USER\""                     # skip user pick, straight to password
    "appearance|scheme|\"Synced\""                # colors from Noctalia
    "appearance|hide_logo|true"                    # no owl
    "appearance|scheme_selector_position|\"hidden\""
    "appearance|power_buttons_position|\"bottom-right\""
    "clock|enabled|true"
    "clock|position|\"top-center\""
    "clock|time_format|\"{:%H:%M}\""
    "clock|date_format|\"%A, %B %d\""
    "clock|time_font_size|96"
    "clock|date_font_size|20"
)

GREETD_CONF=/etc/greetd/config.toml
GREETER_TOML=/var/lib/noctalia-greeter/greeter.toml
STAMP="$(date +%Y%m%d-%H%M%S)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
    echo "+ $*"
    [ "$DRY" -eq 1 ] || "$@"
}

[ -f /etc/arch-release ] || { echo "error: Arch/CachyOS only (pacman)." >&2; exit 1; }

apply_greeter_settings() {
    echo ":: 4/6 Greeter look, layout and default session ($GREETER_TOML)"
    if [ "$DRY" -eq 1 ]; then
        printf '   | %s\n' "${GREETER_SETTINGS[@]}"
        return
    fi
    sudo cp "$GREETER_TOML" "$GREETER_TOML.bak-$STAMP" 2>/dev/null || true
    sudo python3 -I "$REPO_DIR/greeter-config.py" "$GREETER_TOML" "${GREETER_SETTINGS[@]}"
}

if [ "$APPEARANCE_ONLY" -eq 1 ]; then
    apply_greeter_settings
    echo
    echo "Done. Log out (power menu: Super+Ctrl+P) to see the new login screen --"
    echo "no need to restart greetd (that would end your session)."
    exit 0
fi


echo ":: 1/6 Installing greetd + noctalia-greeter"
run sudo pacman -S --needed --noconfirm greetd noctalia-greeter

SESSION_CMD="$(command -v noctalia-greeter-session || echo /usr/bin/noctalia-greeter-session)"

echo ":: 2/6 Pointing greetd at noctalia-greeter ($GREETD_CONF)"
if [ "$DRY" -eq 0 ] && [ -f "$GREETD_CONF" ]; then
    sudo cp "$GREETD_CONF" "$GREETD_CONF.bak-$STAMP"
    echo "   backup -> $GREETD_CONF.bak-$STAMP"
fi
# Rewrite only command/user inside [default_session]; keep everything else
# (e.g. [terminal] vt) as the package shipped it.
new_greetd="$({ cat "$GREETD_CONF" 2>/dev/null || true; } | awk -v cmd="$SESSION_CMD" '
    BEGIN { in_ds = 0; done = 0 }
    /^\[/ {
        if (in_ds && !done) { print "command = \"" cmd "\""; print "user = \"greeter\""; done = 1 }
        in_ds = ($0 == "[default_session]")
        if (in_ds) { print; next }
    }
    in_ds && /^[[:space:]]*(command|user)[[:space:]]*=/ { next }
    { print }
    END {
        if (in_ds && !done) { print "command = \"" cmd "\""; print "user = \"greeter\""; done = 1 }
        if (!done) { print ""; print "[default_session]"; print "command = \"" cmd "\""; print "user = \"greeter\"" }
    }')"
if [ "$DRY" -eq 1 ]; then
    printf '%s\n' "$new_greetd" | sed 's/^/   | /'
else
    printf '%s\n' "$new_greetd" | sudo tee "$GREETD_CONF" >/dev/null
fi

echo ":: 3/6 Initializing greeter state"
run sudo systemd-tmpfiles --create noctalia-greeter.conf
run sudo noctalia-greeter-apply-appearance --setup-system
# Lets Noctalia's "Auto-Sync Greeter" push wallpaper/palette on every theme
# switch without an admin password prompt each time.
run sudo noctalia-greeter passwordless-sync enable "$USER"

# greetd's PAM file (unlike SDDM's) has no pam_gnome_keyring, so the login
# keyring stays locked and anything using the Secret Service (browsers, the
# Steam widget's API key, ...) pops "Default keyring is locked" after every
# boot. Same lines SDDM uses; the leading '-' skips them if the module is
# missing. /etc/pam.d/greetd is a pacman backup file, so updates keep this.
PAM_GREETD=/etc/pam.d/greetd
if [ -f "$PAM_GREETD" ] && ! grep -q pam_gnome_keyring "$PAM_GREETD"; then
    echo "   adding pam_gnome_keyring to $PAM_GREETD (keyring unlocks at login)"
    run sudo sed -i.bak-"$STAMP" \
        -e '/^auth[[:space:]]\+include[[:space:]]\+system-local-login/a -auth       optional     pam_gnome_keyring.so' \
        -e '/^session[[:space:]]\+include[[:space:]]\+system-local-login/a -session    optional     pam_gnome_keyring.so auto_start' \
        "$PAM_GREETD"
fi

apply_greeter_settings

echo ":: 5/6 Checking the greeter can see the sessions"
if [ "$DRY" -eq 0 ]; then
    noctalia-greeter sessions 2>/dev/null || echo "   (could not list sessions; check after reboot)"
fi

echo ":: 6/6 Switching display manager at next boot (SDDM stays installed)"
current="$(systemctl show -p Id --value display-manager.service 2>/dev/null || true)"
if [ -n "$current" ] && [ "$current" != "greetd.service" ]; then
    run sudo systemctl disable "$current"
fi
run sudo systemctl enable greetd.service

cat <<EOF

Done. Reboot to get the new login screen.

In Noctalia: Settings -> Security -> Noctalia Greeter -> turn on "Auto-Sync
Greeter" (or press "Sync Now") so the login screen picks up your wallpaper
and palette.

If the login screen doesn't come up: Ctrl+Alt+F2, log in, then
  sudo systemctl disable greetd && sudo systemctl enable sddm && sudo reboot
EOF
