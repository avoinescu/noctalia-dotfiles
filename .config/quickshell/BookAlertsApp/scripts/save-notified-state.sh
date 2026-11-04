#!/usr/bin/env bash
#
# Reads one line of JSON from stdin (the {id: changedAt} notified-state map
# built in BookAlertsWindow.qml) and persists it, mirroring the stdin-write
# pattern SteamLibraryApp's save-credentials.sh already uses for the same
# reason -- read with a timeout rather than waiting for EOF, since the QML
# side may leave the pipe open.

set -uo pipefail

STATE_FILE="$HOME/.cache/book-alerts/notified-state.json"
mkdir -p "$(dirname "$STATE_FILE")"

fail() {
    echo '{"success":false}'
    exit 0
}

IFS= read -r -t 5 payload || fail
jq -e . >/dev/null 2>&1 <<<"$payload" || fail

printf '%s' "$payload" > "$STATE_FILE"
echo '{"success":true}'
