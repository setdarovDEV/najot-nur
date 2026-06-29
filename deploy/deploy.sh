#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NotiqAI — bootstrap production deployment on a fresh VPS.
#  Idempotent: safe to re-run after a code update.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/.."

export DEBIAN_FRONTEND=noninteractive

require() { command -v "$1" >/dev/null 2>&1 || { echo "✗ $1 topilmadi" >&2; exit 1; }; }
require docker
docker compose version >/dev/null

# ── 1) .env bormi? ──
if [[ ! -f .env ]]; then
  echo "• .env topilmadi, namunadan yaratyapman (.env.production)…"
  cp deploy/env.production .env
  chmod 600 .env
fi

# ── 2) Build + up ──
echo "• Docker image'lar build qilinyapti…"
docker compose -f docker-compose.yml -f docker-compose.prod.yml build --pull

echo "• Servislar ishga tushirilmoqda…"
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# ── 3) healthcheck kutamiz ──
echo "• Backend healthcheck kutilyapti…"
for i in {1..40}; do
  if curl -fsS http://localhost/health >/dev/null 2>&1; then
    echo "✓ Backend tayyor."
    break
  fi
  sleep 2
  if [[ $i -eq 40 ]]; then
    echo "✗ Backend 80 soniyada tayyor bo'lmadi. Loglarni ko'ring:"
    docker compose -f docker-compose.yml -f docker-compose.prod.yml logs --tail=80 backend
    exit 1
  fi
done

echo
echo "════════════════════════════════════════════"
echo "  DEPLOY MUVAFFAQIYATLI"
echo "════════════════════════════════════════════"
echo "  Server IP: ${SERVER_IP:-45.138.159.219}"
echo "  Backend API:  http://${SERVER_IP:-45.138.159.219}/api/v1"
echo "  Swagger:      http://${SERVER_IP:-45.138.159.219}/docs"
echo "  Admin panel:  http://${SERVER_IP:-45.138.159.219}/"
echo "  Health:       http://${SERVER_IP:-45.138.159.219}/health"
echo "════════════════════════════════════════════"
