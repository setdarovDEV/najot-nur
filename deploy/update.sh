#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — manual deploy (Watchtower ishlasa kerak emas).
#
#  Bu skriptni faqat shunday holatlarda ishlating:
#    • Watchtower o'chirilgan
#    • Tezkor yangilash kerak (5 minut kutmaslik)
#    • Yangi .env o'zgarishlarini qo'llash
# ════════════════════════════════════════════════════════════════
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ Image lar GHCR dan tortilmoqda..."
docker compose pull

echo "▶ Konteynerlar qayta yaratilmoqda..."
docker compose up -d

echo "▶ Eski imagelar tozalanmoqda..."
docker image prune -f

echo "✓ Deploy yakunlandi."
docker compose ps
