#!/usr/bin/env bash
#
# Records "now" as the last time the Book Alerts panel was opened, so
# bar-format.sh can show an unread-since-last-viewed count instead of the
# raw 14-day rolling-window total (which only ever grows/plateaus and never
# reflects "have I already looked at this"). Atomic write (temp file + mv +
# trap cleanup) to avoid the leftover-tmpfile bug seen in
# ~/.cache/steam-library/.

set -uo pipefail

DIR="$HOME/.cache/book-alerts"
DEST="$DIR/last-viewed.json"
mkdir -p "$DIR"

TMP="$(mktemp "$DIR/.last-viewed.json.XXXXXX")"
trap 'rm -f "$TMP"' EXIT INT TERM

printf '{"lastViewedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TMP"
mv "$TMP" "$DEST"
