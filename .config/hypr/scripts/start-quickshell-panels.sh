#!/usr/bin/env bash
# Trimmed down once Noctalia became the sole daily-driver shell: this used
# to also seed/restore ml4w's own wallpaper cache and run the full
# ml4w-wallpaper/Matugen pipeline on every login, but that read ml4w's own
# stale cache file rather than Noctalia's actual current wallpaper
# (~/.local/state/noctalia/settings.toml's [wallpaper] block) -- a latent
# wallpaper-flash-on-login bug now moot since Noctalia owns wallpaper
# picking/theming entirely. All that's left here is starting the two
# Quickshell panels with no Noctalia equivalent (Power, AI-usage, in
# shell.qml) and the standalone Overview switcher.

# Colors for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- UI Functions (Redirected to stderr) ---
info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Start nmapplet
nm-applet --indicator &

# Quickshell reads its icon theme from QS_ICON_THEME, not from GTK. Hyprland
# normally exports it (conf/environment.lua); fall back to reading the GTK
# settings here so a manual run of this script still themes the dock icons.
if [ -z "$QS_ICON_THEME" ]; then
    GTK_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
    if [ -f "$GTK_SETTINGS" ]; then
        ICON_THEME="$(grep 'gtk-icon-theme-name' "$GTK_SETTINGS" | sed 's/.*\s*=\s*//')"
        [ -n "$ICON_THEME" ] && export QS_ICON_THEME="$ICON_THEME"
    fi
fi
info "Quickshell icon theme: ${QS_ICON_THEME:-<unset>}"

# Kill any existing qs instances
killall qs 2>/dev/null || true

# Start Quickshell first
info "Starting Quickshell"
qs &

# Wait for qs process to be ready, then let IPC initialize
info "Waiting for Quickshell..."
timeout=15
elapsed=0
until pgrep -x qs >/dev/null 2>&1; do
    sleep 0.2
    elapsed=$((elapsed + 1))
    if [ $elapsed -ge $((timeout * 5)) ]; then
        warn "Quickshell did not start within ${timeout}s"
        break
    fi
done
sleep 0.5
info "Quickshell ready"

# Start Quickshell Overview
info "Starting Quickshell Overview"
qs -p $HOME/.config/quickshell/overview &
info "Quickshell Overview started"
