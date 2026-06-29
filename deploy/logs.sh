#!/usr/bin/env bash
# NotiqAI — tail logs of all services.
cd "$(dirname "$0")/.."
docker compose -f docker-compose.production.yml logs -f --tail=100 "$@"
