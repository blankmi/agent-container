#!/usr/bin/env bash
set -e
DATE=$(date +%Y-%m-%d)
IMAGE="local/agent-base:${DATE}"
docker build --pull --no-cache -t "$IMAGE" "$(dirname "$0")"
echo "Built: $IMAGE"
