#!/usr/bin/env bash
# NotiqAI — pull latest code and restart.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "• Pulling/uploading code…"
# (skipped — deployment is via scp from local)

echo "• Rebuilding images…"
docker compose -f docker-compose.production.yml build

echo "• Restarting services…"
docker compose -f docker-compose.production.yml up -d

echo "• Pruning old images…"
docker image prune -f

echo "✓ Update complete."
docker compose -f docker-compose.production.yml ps
