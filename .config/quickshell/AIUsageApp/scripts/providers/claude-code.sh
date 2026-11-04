#!/usr/bin/env bash
#
# Claude Code usage provider for the ai-usage dropdown panel.
#
# Outputs: {id, name, plan, available, limits[], tokens_by_day[], tokens_by_model[]}
# (see collect.sh for the full contract every provider must follow.)
#
# Two independent data sources, both local/first-party, no third-party service:
#   1. Session/Weekly rate-limit % — Anthropic's own account endpoint,
#      api.anthropic.com/api/oauth/usage, authenticated with the OAuth token
#      `claude` already stores at ~/.claude/.credentials.json. Refreshed via
#      platform.claude.com/v1/oauth/token when near expiry (CLIENT_ID below
#      is Claude Code's own public OAuth client id, not a secret).
#   2. Tokens by day / by model — summed locally from your own session
#      transcripts under ~/.claude/projects/*.jsonl (written by `claude`
#      itself). Never leaves this machine.
#
# Cached for CACHE_TTL seconds so opening the panel repeatedly doesn't spam
# the API or re-scan every transcript. Pass "--force" to bypass the cache.

set -uo pipefail

CREDS="$HOME/.claude/.credentials.json"
CACHE_DIR="$HOME/.cache/ai-usage"
CACHE_FILE="$CACHE_DIR/claude-code.json"
CACHE_TTL=120
CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
REFRESH_BUFFER=300
FORCE="${1:-}"

mkdir -p "$CACHE_DIR"

unavailable() {
    jq -nc --arg msg "$1" \
        '{id:"claude-code", name:"Claude Code", plan:"", available:false, message:$msg, limits:[], tokens_by_day:[], tokens_by_model:[]}'
    exit 0
}

command -v jq >/dev/null 2>&1 || unavailable "jq is not installed"

if [ "$FORCE" != "--force" ] && [ -f "$CACHE_FILE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if [ "$age" -lt "$CACHE_TTL" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

[ -f "$CREDS" ] || unavailable "not logged in (~/.claude/.credentials.json not found)"

creds=$(cat "$CREDS")
access_token=$(jq -r '.claudeAiOauth.accessToken // empty' <<<"$creds")
refresh_token=$(jq -r '.claudeAiOauth.refreshToken // empty' <<<"$creds")
expires_at=$(jq -r '.claudeAiOauth.expiresAt // 0' <<<"$creds")
plan_raw=$(jq -r '.claudeAiOauth.subscriptionType // "claude"' <<<"$creds")
plan=$(echo "$plan_raw" | tr '_' ' ' | tr '[:lower:]' '[:upper:]')

[ -n "$access_token" ] || unavailable "no access token in credentials file"

now_ms=$(date +%s%3N)

# Refresh if the access token expires within REFRESH_BUFFER seconds.
if [ -n "$refresh_token" ] && [ $(( (expires_at - now_ms) / 1000 )) -lt "$REFRESH_BUFFER" ]; then
    resp=$(curl -fsS --proto '=https' --tlsv1.2 -X POST "https://platform.claude.com/v1/oauth/token" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc --arg ci "$CLIENT_ID" --arg rt "$refresh_token" \
             '{grant_type:"refresh_token", client_id:$ci, refresh_token:$rt}')" 2>/dev/null)

    new_access=$(jq -r '.access_token // empty' <<<"${resp:-null}" 2>/dev/null)
    if [ -n "$new_access" ]; then
        new_refresh=$(jq -r '.refresh_token // empty' <<<"$resp")
        expires_in=$(jq -r '.expires_in // 0' <<<"$resp")
        new_expires_at=$(( now_ms + expires_in * 1000 ))
        tmp=$(mktemp "$CREDS.XXXXXX")
        jq --arg at "$new_access" \
           --arg rt "${new_refresh:-$refresh_token}" \
           --argjson ea "$new_expires_at" \
           '.claudeAiOauth.accessToken=$at | .claudeAiOauth.refreshToken=$rt | .claudeAiOauth.expiresAt=$ea' \
           <<<"$creds" > "$tmp" && mv "$tmp" "$CREDS"
        chmod 600 "$CREDS"
        access_token="$new_access"
    fi
fi

usage=$(curl -fsS --proto '=https' --tlsv1.2 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $access_token" 2>/dev/null)
[ -n "$usage" ] || unavailable "usage fetch failed (network or expired session)"

fmt_reset() {
    local iso="$1" target now diff h m
    [ -n "$iso" ] && [ "$iso" != "null" ] || { echo "?"; return; }
    target=$(date -d "$iso" +%s 2>/dev/null) || { echo "?"; return; }
    now=$(date +%s)
    diff=$(( target - now ))
    [ "$diff" -lt 0 ] && diff=0
    h=$(( diff / 3600 ))
    m=$(( (diff % 3600) / 60 ))
    printf '%dh %dm' "$h" "$m"
}

session_pct=$(jq -r '((.five_hour.utilization // 0) | round)' <<<"$usage")
session_left=$(fmt_reset "$(jq -r '.five_hour.resets_at // empty' <<<"$usage")")
weekly_pct=$(jq -r '((.seven_day.utilization // 0) | round)' <<<"$usage")
weekly_left=$(fmt_reset "$(jq -r '.seven_day.resets_at // empty' <<<"$usage")")

limits_json=$(jq -nc \
    --argjson sp "$session_pct" --arg sl "$session_left" \
    --argjson wp "$weekly_pct" --arg wl "$weekly_left" \
    '[{label:"Session", percent:$sp, resets_in:$sl}, {label:"Weekly", percent:$wp, resets_in:$wl}]')

# --- Local token tally from this machine's own transcripts ---

declare -A day_tokens
declare -A model_tokens

while IFS=$'\t' read -r date model tokens; do
    [ -z "$date" ] && continue
    day_tokens["$date"]=$(( ${day_tokens["$date"]:-0} + tokens ))
    model_tokens["$model"]=$(( ${model_tokens["$model"]:-0} + tokens ))
done < <(jq -r 'select(.type=="assistant" and .message.usage != null) |
    ((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0) +
     (.message.usage.cache_creation_input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0)) as $tok |
    select($tok > 0) |
    [(.timestamp[0:10]), (.message.model // "unknown"), $tok] | @tsv' "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null)

days_json="["
for i in 6 5 4 3 2 1 0; do
    d=$(date -d "-$i day" +%F)
    if [ "$i" -eq 0 ]; then label="Today"; else label=$(date -d "-$i day" +%a); fi
    val=${day_tokens["$d"]:-0}
    days_json+="{\"label\":\"$label\",\"value\":$val},"
done
days_json="${days_json%,}]"

models_json="["
while IFS=$'\t' read -r tokens model; do
    [ -z "$model" ] && continue
    models_json+="{\"label\":\"$model\",\"value\":$tokens},"
done < <(for m in "${!model_tokens[@]}"; do printf '%s\t%s\n' "${model_tokens[$m]}" "$m"; done | sort -rn | head -5)
models_json="${models_json%,}]"

result=$(jq -nc \
    --arg plan "$plan" \
    --argjson limits "$limits_json" \
    --argjson days "$days_json" \
    --argjson models "$models_json" \
    '{id:"claude-code", name:"Claude Code", plan:$plan, available:true, limits:$limits, tokens_by_day:$days, tokens_by_model:$models}')

echo "$result" > "$CACHE_FILE"
echo "$result"
