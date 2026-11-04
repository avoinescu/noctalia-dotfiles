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
# Usage: ./setup-greeter.sh          (prompts for sudo as needed)
#        ./setup-greeter.sh --dry-run  (print what would change)
set -euo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# --- Layout: keep in sync with .config/hypr/modules/monitors.lua -----------
LOGIN_OUTPUT="DP-1"                          # 32" -- shows the login form
LAYOUT="DP-1:0,0; DP-2:2560,0"               # 34" ultrawide to the right
REFRESH="DP-1:165; DP-2:144"
DEFAULT_SESSION="Hyprland"                   # Name= from /usr/share/wayland-sessions
# ---------------------------------------------------------------------------

GREETD_CONF=/etc/greetd/config.toml
GREETER_TOML=/var/lib/noctalia-greeter/greeter.toml
STAMP="$(date +%Y%m%d-%H%M%S)"

run() {
    echo "+ $*"
    [ "$DRY" -eq 1 ] || "$@"
}

[ -f /etc/arch-release ] || { echo "error: Arch/CachyOS only (pacman)." >&2; exit 1; }

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

echo ":: 4/6 Monitor layout + default session ($GREETER_TOML)"
block="$(cat <<EOF

# --- managed by noctalia-dotfiles/setup-greeter.sh ---
# Mirrors .config/hypr/modules/monitors.lua. These win over values synced
# from Noctalia (sync.toml), so the layout can't drift.
[output]
name = "$LOGIN_OUTPUT"
layout = "$LAYOUT"
refresh_rate = "$REFRESH"

[session]
default = "$DEFAULT_SESSION"
EOF
)"
if [ "$DRY" -eq 1 ]; then
    printf '%s\n' "$block" | sed 's/^/   | /'
elif sudo grep -qE '^\[(output|session)\]' "$GREETER_TOML" 2>/dev/null; then
    echo "   NOTE: $GREETER_TOML already has an [output] or [session] table;"
    echo "   not touching it. Make sure it contains:"
    printf '%s\n' "$block" | sed 's/^/   | /'
else
    sudo cp "$GREETER_TOML" "$GREETER_TOML.bak-$STAMP" 2>/dev/null || true
    printf '%s\n' "$block" | sudo tee -a "$GREETER_TOML" >/dev/null
fi

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
