#!/usr/bin/env bash
set -e
DATE=$(date +%Y-%m-%d)
ROOT="$(cd "$(dirname "$0")" && pwd)"

docker build --pull --no-cache \
  -t "local/agent-base:$DATE" \
  -f "$ROOT/Dockerfile" \
  "$ROOT"

for agent in claude codex junie; do
  docker build --no-cache \
    --build-arg "BASE_DATE=$DATE" \
    -t "local/agent-$agent:$DATE" \
    -f "$ROOT/Dockerfile.$agent" \
    "$ROOT"
done

for agent in claude codex; do
  docker volume create "agent-creds-$agent" >/dev/null
done

echo "Built: local/agent-{base,claude,codex,junie}:$DATE"
echo "Volumes: agent-creds-{claude,codex} ready"
