#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — one-shot server bootstrap.
#  Wipes Dokploy + old notiqai, clones the project from GitHub,
#  sets up .env with strong passwords, starts the new stack.
#
#  Usage (on the server, as root):
#    curl -fsSL https://raw.githubusercontent.com/setdarovDEV/najot-nur/main/deploy/bootstrap.sh | bash
#
#  Or if you have the repo locally:
#    bash deploy/bootstrap.sh
# ════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_URL="https://github.com/setdarovDEV/najot-nur.git"
BRANCH="main"
INSTALL_DIR="/opt/notiqai"

# ── helpers ─────────────────────────────────────────────────
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
banner() { printf '\n\033[1;36m=== %s ===\033[0m\n\n' "$*"; }

# ── 0) Root check ──────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  red "✗ Root bo'lib ishga tushiring:  sudo bash $0"
  exit 1
fi

# ── 1) Pre-flight ──────────────────────────────────────────
banner "NotiqAI — server bootstrap"
yellow "Bu skript quyidagilarni o'chiradi:"
yellow "  • Dokploy (konteyner, konfiguratsiya, ma'lumotlar)"
yellow "  • notiq_ bilan boshlangan barcha konteynerlar"
yellow "  • postgres, redis, media volume larni (eski notiqai dan)"
yellow "  • /etc/dokploy papkasini"
echo
yellow "⚠ DIQQAT: Barcha ma'lumotlar O'CHIB KETADI (DB, media)."
echo
read -rp "Davom etasizmi? 'yes' yozing: " ans
[[ "$ans" == "yes" ]] || { red "Bekor qilindi."; exit 1; }

# ── 2) Docker check ────────────────────────────────────────
banner "1/7 · Docker tekshirilmoqda"
if ! command -v docker >/dev/null 2>&1; then
  yellow "Docker topilmadi. O'rnatilmoqda..."
  apt-get update -qq
  apt-get install -y -qq docker.io docker-compose-plugin
  systemctl enable --now docker
  green "✓ Docker o'rnatildi"
else
  green "✓ Docker mavjud"
fi
docker compose version >/dev/null 2>&1 || {
  red "✗ docker compose topilmadi"
  exit 1
}

# ── 3) Wipe Dokploy ────────────────────────────────────────
banner "2/7 · Dokploy o'chirilmoqda"

# Stop all containers
echo "→ Barcha konteynerlar to'xtatilmoqda..."
docker ps -q | xargs -r docker stop 2>/dev/null || true

# Remove Dokploy-specific containers
for c in $(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -iE 'dokploy' || true); do
  echo "  rm: $c"
  docker rm -f "$c" 2>/dev/null || true
done

# Remove notiqai-related containers
for c in $(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E '^notiq_' || true); do
  echo "  rm: $c"
  docker rm -f "$c" 2>/dev/null || true
done

# Remove Dokploy compose projects
for p in $(docker compose ls --format json 2>/dev/null | python3 -c "import sys,json; [print(p['Name']) for p in json.load(sys.stdin) if 'dokploy' in p.get('Name','').lower() or 'notiq' in p.get('Name','').lower()]" 2>/dev/null || true); do
  echo "  compose down: $p"
  cd "/etc/dokploy/compose/$p" 2>/dev/null && docker compose down --remove-orphans 2>/dev/null || true
done

# Remove Dokploy directories
rm -rf /etc/dokploy
rm -rf /opt/dokploy
green "✓ Dokploy o'chirildi"

# ── 4) Clean leftover networks and volumes ────────────────
banner "3/7 · Docker network va volume larni tozalash"

for n in $(docker network ls --format '{{.Name}}' 2>/dev/null | grep -iE 'dokploy|notiq' || true); do
  echo "  net rm: $n"
  docker network rm "$n" 2>/dev/null || true
done

for v in $(docker volume ls --format '{{.Name}}' 2>/dev/null | grep -iE 'notiq|postgres|redis|media' || true); do
  echo "  vol rm: $v"
  docker volume rm "$v" 2>/dev/null || true
done

green "✓ Docker resurslar tozalandi"

# ── 5) Clone / pull project ────────────────────────────────
banner "4/7 · Loyiha o'rnatilmoqda"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "→ Loyiha allaqachon mavjud, yangilanmoqda..."
  cd "$INSTALL_DIR"
  git fetch origin
  git reset --hard "origin/$BRANCH"
else
  echo "→ Loyiha klonlanmoqda..."
  rm -rf "$INSTALL_DIR"
  git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

green "✓ Kod tayyor: $INSTALL_DIR"

# ── 6) .env generation ────────────────────────────────────
banner "5/7 · .env tayyorlanmoqda"

if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  cp "$INSTALL_DIR/.env.production.example" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"

  # Generate strong passwords
  POSTGRES_PASS=$(openssl rand -hex 24)
  JWT_SECRET=$(openssl rand -hex 32)

  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASS|" "$INSTALL_DIR/.env"
  sed -i "s|^JWT_SECRET_KEY=.*|JWT_SECRET_KEY=$JWT_SECRET|" "$INSTALL_DIR/.env"
  sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgresql+asyncpg://notiq:$POSTGRES_PASS@postgres:5432/notiqai|" "$INSTALL_DIR/.env"
  sed -i "s|^RUN_SEEDS=.*|RUN_SEEDS=true|" "$INSTALL_DIR/.env"

  green "✓ Kuchli parollar generatsiya qilindi"
  echo
  yellow "⚠ MUHIM: .env ni hozir tahrirlang:"
  yellow "    nano $INSTALL_DIR/.env"
  echo
  yellow "  Quyidagilarni to'ldiring:"
  yellow "    CORS_ORIGINS  (https://notiqlik.uz,https://admin.notiqlik.uz,...)"
  yellow "    OTP_PROVIDER  (telegram yoki sms)"
  yellow "    AI_PROVIDER   (mock / claude / gemini / groq)"
  yellow "    FCM_ENABLED, FCM_PROJECT_ID (push)"
  yellow "    OAuth: GOOGLE_*, TELEGRAM_BOT_*"
  yellow "    SMS: ESKIZ_*, SMS_API_* (OTP uchun)"
  yellow "    AI: GEMINI_API_KEY / GROQ_API_KEY / ANTHROPIC_API_KEY"
  echo
  yellow "  Tahrir qilgach, shu skriptni qayta ishga tushiring:"
  yellow "    bash $0"
  echo
  read -rp "Hozir tahrirlaysizmi? (y/n): " edit_now
  if [[ "$edit_now" == "y" ]]; then
    # Editor tanlash: nano > vi > apt install nano
    if command -v nano >/dev/null 2>&1; then
      EDITOR_CMD=nano
    elif command -v vi >/dev/null 2>&1; then
      EDITOR_CMD=vi
    else
      apt-get install -y -qq nano >/dev/null 2>&1 && EDITOR_CMD=nano || EDITOR_CMD=vi
    fi
    $EDITOR_CMD "$INSTALL_DIR/.env"
    echo
    yellow "Davom etish uchun Enter bosing (yoki Ctrl+C bilan chiqing va keyin qayta ishga tushiring)..."
    read -r
  fi
else
  green "✓ .env allaqachon mavjud"
fi

# ── 7) Pull images and start ──────────────────────────────
banner "6/7 · Image lar tortilmoqda va stack ishga tushirilmoqda"

cd "$INSTALL_DIR"
docker compose pull
docker compose up -d

# ── 8) Verify ──────────────────────────────────────────────
banner "7/7 · Tekshirish"

echo "→ 30 soniya kuting (servislar start bo'lmoqda)..."
sleep 30

echo
echo "→ Konteyner holati:"
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}' || true

echo
echo "→ Caddy tayyor bo'lishini kutish (Let's Encrypt, 1-2 daqiqa)..."
for i in {1..30}; do
  if curl -fsS -o /dev/null -m 5 "https://notiqlik.uz" 2>/dev/null; then
    green "✓ HTTPS ishlayapti!"
    break
  fi
  sleep 5
done

echo
echo "→ Tekshirish URL lari:"
echo "    https://notiqlik.uz"
echo "    https://admin.notiqlik.uz"
echo "    https://curator.notiqlik.uz"
echo "    https://api.notiqlik.uz/docs"

# ── done ───────────────────────────────────────────────────
banner "✓ TAYYOR"
echo "Kod:       $INSTALL_DIR"
echo "Loglar:    cd $INSTALL_DIR && docker compose logs -f"
echo "Yangilash: cd $INSTALL_DIR && docker compose pull && docker compose up -d"
echo
echo "Auto-update: Watchtower har 5 daqiqada yangi image bor-yo'qligini tekshiradi."
echo "Faqat lokal'da:  git push origin main  → hamma narsa avtomatik yangilanadi."
