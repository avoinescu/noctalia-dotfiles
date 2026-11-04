#!/usr/bin/env bash
#
# Codex provider stub for the ai-usage dropdown panel.
#
# Unlike Claude Code, OpenAI's Codex CLI doesn't expose a local rate-limit
# quota endpoint we could find (~/.codex only holds diagnostic sqlite logs,
# no token/usage accounting). Rather than fake numbers, this reports itself
# as unavailable so the tab shows up with an honest placeholder.
#
# To wire in real data later: replace this script's output with the same
# {id, name, plan, available, limits[], tokens_by_day[], tokens_by_model[]}
# shape used by claude-code.sh — that's the only contract collect.sh and the
# Quickshell panel care about. Any other AI tool can be added the same way:
# drop an executable script in this directory that prints this shape.

jq -nc '{
    id: "codex",
    name: "Codex",
    plan: "",
    available: false,
    message: "No local usage/quota API found for Codex yet — this is a placeholder tab. Wire in real data here once there is a source for it.",
    limits: [],
    tokens_by_day: [],
    tokens_by_model: []
}'
