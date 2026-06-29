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
  echo "• .env topilmadi, namunadan yaratyapman…"
  cp .env.production.example .env
  chmod 600 .env
  echo
  echo "  ⚠ MUHIM: .env faylini hozir tahrirlang!"
  echo "    nano .env"
  echo "    Quyidagilarni albatta to'ldiring:"
  echo "      POSTGRES_PASSWORD, JWT_SECRET_KEY, CORS_ORIGINS,"
  echo "      OTP_PROVIDER, AI_PROVIDER, FCM_ENABLED, RUN_SEEDS"
  echo
  echo "  Keyin qayta ishga tushiring:  bash deploy/deploy.sh"
  exit 1
fi

# ── 2) Build + up ──
echo "• Docker image'lar build qilinyapti…"
docker compose -f docker-compose.production.yml build --pull

echo "• Servislar ishga tushirilmoqda…"
docker compose -f docker-compose.production.yml up -d

# ── 3) healthcheck kutamiz ──
echo "• Backend healthcheck kutilyapti…"
for i in {1..40}; do
  if curl -fsS http://localhost/healthz >/dev/null 2>&1; then
    echo "✓ Nginx tayyor."
    break
  fi
  sleep 2
  if [[ $i -eq 40 ]]; then
    echo "✗ Servislar 80 soniyada tayyor bo'lmadi. Loglarni ko'ring:"
    docker compose -f docker-compose.production.yml logs --tail=80 nginx
    exit 1
  fi
done

echo
echo "════════════════════════════════════════════"
echo "  DEPLOY MUVAFFAQIYATLI"
echo "════════════════════════════════════════════"
echo "  Server IP: ${SERVER_IP:-45.138.159.219}"
echo "  Keyingi qadam: Dokploy UI'dan 4 ta domenni"
echo "  'nginx' service'ga (port 80) ulang."
echo "  Qo'llanma: deploy/README.md"
echo "════════════════════════════════════════════"
