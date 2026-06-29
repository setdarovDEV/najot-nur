#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — yangi serverni bir marta sozlash.
#
#  Bu skript:
#    1) /opt/notiqai papkasini tayyorlaydi
#    2) Kod va konfiguratsiyani shu yerga ko'chiradi
#    3) .env ni namunadan yaratadi (siz keyin tahrirlaysiz)
#    4) Eski konteyner / image larni tozalaydi
#    5) docker compose up -d
#
#  ⚠ Bu skriptni FAQAT birinchi marta yoki to'liq qayta
#  o'rnatishda ishlating. Keyingi yangilanishlar uchun
#  `update.sh` ishlating (yoki hech narsa — Watchtower
#  avtomatik qiladi).
# ════════════════════════════════════════════════════════════════
set -euo pipefail

# Bitta manba nuqtasi — skript qayerda bo'lsa
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Standart o'rnatish joyi
INSTALL_DIR="${INSTALL_DIR:-/opt/notiqai}"

echo "═══════════════════════════════════════════════════════════"
echo "  NotiqAI — server sozlash"
echo "═══════════════════════════════════════════════════════════"
echo "  Manba:        $PROJECT_DIR"
echo "  O'rnatish:    $INSTALL_DIR"
echo

# ── 1) root tekshirish ────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "✗ Root bo'lib ishga tushiring (sudo bash $0)"
  exit 1
fi

# ── 2) Docker tekshirish ───────────────────────────────────
command -v docker >/dev/null || { echo "✗ docker topilmadi"; exit 1; }
docker compose version >/dev/null || { echo "✗ docker compose topilmadi"; exit 1; }

# ── 3) Port 80/443 bo'shmi? ───────────────────────────────
if ss -tlnp 2>/dev/null | grep -qE ':(80|443)\s'; then
  echo "✗ Port 80 yoki 443 band:"
  ss -tlnp 2>/dev/null | grep -E ':(80|443)\s'
  echo "  Avval Dokploy'ni o'chiring: bash teardown-dokploy.sh"
  exit 1
fi

# ── 4) Loyihani ko'chirish ────────────────────────────────
echo "▶ 1) Loyiha $INSTALL_DIR ga ko'chirilmoqda..."
mkdir -p "$INSTALL_DIR"
rsync -a --delete \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='node_modules' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='.venv' \
  --exclude='venv' \
  --exclude='.pytest_cache' \
  --exclude='.ruff_cache' \
  --exclude='admin/dist' \
  --exclude='admin/node_modules' \
  --exclude='curator/dist' \
  --exclude='curator/node_modules' \
  --exclude='landing/dist' \
  --exclude='landing/node_modules' \
  --exclude='backend/media' \
  --exclude='bugs' \
  "$PROJECT_DIR/" "$INSTALL_DIR/"

# ── 5) .env tayyorlash ────────────────────────────────────
if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  echo
  echo "▶ 2) .env yaratilmoqda..."
  cp "$INSTALL_DIR/.env.production.example" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"

  # Kuchli parollar generatsiya qilish
  POSTGRES_PASS=$(openssl rand -hex 24)
  JWT_SECRET=$(openssl rand -hex 32)
  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASS|" "$INSTALL_DIR/.env"
  sed -i "s|^JWT_SECRET_KEY=.*|JWT_SECRET_KEY=$JWT_SECRET|" "$INSTALL_DIR/.env"
  sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgresql+asyncpg://notiq:$POSTGRES_PASS@postgres:5432/notiqai|" "$INSTALL_DIR/.env"

  echo "  ✓ Kuchli parollar generatsiya qilindi"
  echo
  echo "  ⚠ .env ni hozir tahrirlang va quyidagilarni to'ldiring:"
  echo "    - CORS_ORIGINS (domenlar ro'yxati)"
  echo "    - OTP_PROVIDER (telegram yoki sms)"
  echo "    - AI_PROVIDER (mock / claude / gemini)"
  echo "    - FCM_ENABLED, FCM_PROJECT_ID (push notifications)"
  echo "    - Birinchi marta: RUN_SEEDS=true (keyin false qiling)"
  echo
  echo "  nano $INSTALL_DIR/.env"
  echo
  echo "Tahrirlagach, shu skriptni qayta ishga tushiring."
  exit 0
fi

# ── 6) Eski image va konteynerlarni tozalash ──────────────
echo "▶ 3) Eski konteyner va imagelarni tozalash..."
cd "$INSTALL_DIR"
docker compose down --remove-orphans 2>/dev/null || true
docker image prune -f 2>/dev/null || true

# ── 7) Image larni tortish va ishga tushirish ─────────────
echo "▶ 4) Image lar GHCR dan tortilmoqda..."
docker compose pull

echo "▶ 5) Servislar ishga tushirilmoqda..."
docker compose up -d

# ── 8) Healthcheck ────────────────────────────────────────
echo "▶ 6) Healthcheck..."
for i in {1..40}; do
  if curl -fsS http://127.0.0.1:8080/healthz >/dev/null 2>&1; then
    echo "  ✓ nginx tayyor (internal)"
    break
  fi
  sleep 2
  if [[ $i -eq 40 ]]; then
    echo "  ✗ nginx 80 soniyada tayyor bo'lmadi. Loglarni ko'ring:"
    docker compose logs --tail=80 nginx
    exit 1
  fi
done

# ── 9) Caddy tayyor ───────────────────────────────────────
echo "▶ 7) Caddy tayyor bo'lishini kutish (Let's Encrypt)..."
for i in {1..20}; do
  if curl -fsS -o /dev/null http://127.0.0.1:80 2>/dev/null; then
    echo "  ✓ Caddy 80-portda javob beradi"
    break
  fi
  sleep 3
done

echo
echo "═══════════════════════════════════════════════════════════"
echo "  ✓ TAYYOR"
echo "═══════════════════════════════════════════════════════════"
echo
echo "  Tabriklayman! NotiqAI endi serverda ishlayapti."
echo
echo "  Tekshirish (1-2 daqiqa kuting — Let's Encrypt):"
echo "    https://notiqlik.uz"
echo "    https://www.notiqlik.uz"
echo "    https://admin.notiqlik.uz"
echo "    https://curator.notiqlik.uz"
echo "    https://api.notiqlik.uz/docs"
echo
echo "  Auto-deploy:"
echo "    Lokal'da kodni o'zgartiring → git push origin main"
echo "    → GH Actions image quradi → Watchtower 5 daqiqada yangilaydi"
echo
echo "  Foydali buyruqlar:"
echo "    cd $INSTALL_DIR"
echo "    deploy/logs.sh                 # hamma konteyner loglari"
echo "    deploy/logs.sh backend         # bitta servis"
echo "    deploy/backup.sh               # DB backup"
echo "    docker compose ps              # konteyner holati"
echo
echo "  ⚠ Eslatma: GitHub'da 4 ta GHCR image PUBLIC bo'lishi kerak"
echo "    (https://github.com/setdarovDEV?tab=packages)"
echo
