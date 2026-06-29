#!/usr/bin/env bash
# NotiqAI — pull latest images and restart.
#
# Use this when GitHub Actions has already built & pushed new images
# to ghcr.io. If you pushed to main, just wait a moment for GH Actions
# to finish, then run this script.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "• Pulling latest images from ghcr.io…"
docker compose -f docker-compose.yml pull

echo "• Recreating containers…"
docker compose -f docker-compose.yml up -d

echo "• Pruning old images…"
docker image prune -f

echo "✓ Update complete."
docker compose -f docker-compose.yml ps
