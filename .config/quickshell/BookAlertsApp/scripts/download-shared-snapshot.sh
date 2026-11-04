#!/usr/bin/env bash
#
# Pulls the JSON snapshot n8n writes on icecrown and uploads to Proton
# Drive (see homelab-setup/hosts/icecrown/book-alerts.tf) down to this
# desktop's local cache, where BookAlertsWindow.qml's FileView watches it.
# Runs as a systemd --user timer (book-alerts-download.timer), which
# already runs inside this user's own session -- no D-Bus/keyring
# workaround needed here, unlike the icecrown upload side, since this
# isn't a system-level service impersonating a user.
#
# Downloads into a fresh temp directory first, then atomically renames the
# result into place, so FileView's watchChanges never sees a half-written
# file. The cleanup trap fires on every exit path (not just success) --
# ~/.cache/steam-library/ was found this session to have ~15 leftover temp
# files from an atomic-write path that never cleaned up on failure, so
# this is deliberately not repeating that.

set -Eeuo pipefail

DEST_DIR="$HOME/.cache/book-alerts"
DEST="$DEST_DIR/shared-snapshot.json"
REMOTE="/my-files/BookAlerts/book-alerts-state.json"

mkdir -p "$DEST_DIR"

TMP_DIR="$(mktemp -d "$DEST_DIR/.download-XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT INT TERM

if ! proton-drive filesystem download "$REMOTE" "$TMP_DIR" >/dev/null 2>&1; then
    echo "book-alerts: download failed, keeping previous cached snapshot" >&2
    exit 1
fi

if [ ! -f "$TMP_DIR/book-alerts-state.json" ]; then
    echo "book-alerts: download reported success but file missing, keeping previous cached snapshot" >&2
    exit 1
fi

mv -f "$TMP_DIR/book-alerts-state.json" "$DEST"
