#!/usr/bin/env bash
#
# Stores the Steam Web API key + SteamID64 entered in the panel's setup form
# into the freedesktop Secret Service (gnome-keyring on this machine, same
# encrypted-at-rest store browsers/GNOME apps use for saved passwords) via
# secret-tool. Never touches disk in plaintext -- collect.sh reads it back
# the same way with `secret-tool lookup`.
#
# A plain hash wouldn't work here: collect.sh has to send the real key back
# to Steam's API on every request, and a hash is one-way -- there's no
# recovering the original from it. Encrypted-at-rest + access-controlled
# retrieval (what this does) is the correct primitive for a credential that
# has to be reused, as opposed to a password you only ever need to verify.
#
# Reads one line of JSON from stdin: {"api_key":"...","steam_id64":"..."}
# (read with a timeout rather than waiting for EOF, since the QML side may
# leave the pipe open) -- never passed as an argv, which `ps` could expose
# to other local users.

set -uo pipefail

SERVICE="steam-library-widget"

fail() {
    jq -nc --arg m "$1" '{success:false, message:$m}'
    exit 0
}

command -v secret-tool >/dev/null 2>&1 || fail "secret-tool not installed (pacman -S libsecret)"
command -v jq >/dev/null 2>&1 || fail "jq is not installed"

IFS= read -r -t 5 payload || fail "no input received"
jq -e . >/dev/null 2>&1 <<<"$payload" || fail "malformed input"

api_key=$(jq -r '.api_key // empty' <<<"$payload")
steam_id64=$(jq -r '.steam_id64 // empty' <<<"$payload")

[ -n "$api_key" ] || fail "API key was empty"
[ -n "$steam_id64" ] || fail "SteamID64 was empty"

printf '%s' "$api_key" | secret-tool store --label="Steam Library Widget: API key" \
    service "$SERVICE" key steam-api-key || fail "failed to store API key in the keyring"

printf '%s' "$steam_id64" | secret-tool store --label="Steam Library Widget: SteamID64" \
    service "$SERVICE" key steam-id64 || fail "failed to store SteamID64 in the keyring"

jq -nc '{success:true}'
