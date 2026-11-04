#!/usr/bin/env bash
#
# Local record of which (id, changedAt) pairs from the n8n-written shared
# snapshot have already been turned into a desktop notification, so the
# panel doesn't re-notify for the same change every time the shared file is
# re-read (e.g. on a Quickshell restart, or a no-op FileView reload). This
# is deliberately separate from n8n's own lastKnown state -- the widget
# never recomputes what changed, only what it has already told the user
# about.

set -uo pipefail

STATE_FILE="$HOME/.cache/book-alerts/notified-state.json"

if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
else
    echo '{}'
fi
