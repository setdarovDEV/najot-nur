#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — Dokploy reverse-proxy qo'shish (serverda ishga tushirish).
#
#  Bu skript production serverda quyidagilarni bajaradi:
#    1. DNS ni tekshiradi (dokploy.notiqlik.uz → server IP)
#    2. Yangi SSL sertifikatini oladi (hamma domenlar bilan)
#    3. SSL server bloklarini yoqadi
#    4. nginx'ni qayta ishga tushiradi
#    5. Dokploy panelini tekshiradi
# ════════════════════════════════════════════════════════════════
set -euo pipefail

cd "$(dirname "$0")/.."

DOMAINS=(
  notiqlik.uz
  www.notiqlik.uz
  admin.notiqlik.uz
  curator.notiqlik.uz
  api.notiqlik.uz
  dokploy.notiqlik.uz
)
SERVER_IP="${SERVER_IP:-45.138.159.219}"
EMAIL="${SSL_EMAIL:-admin@notiqlik.uz}"

echo "════════════════════════════════════════════════════════════"
echo "  NotiqAI — Dokploy proxy + SSL sozlash"
echo "════════════════════════════════════════════════════════════"

# ── 1) DNS tekshirish ──
echo
echo "▶ 1) DNS tekshirilmoqda (${SERVER_IP})…"
ok=1
for d in "${DOMAINS[@]}"; do
  ip=$(dig +short "$d" @8.8.8.8 | head -1 || true)
  if [[ -z "$ip" ]]; then
    echo "  ✗ $d → DNS topilmadi (registrarga A-record qo'shing)"
    ok=0
  elif [[ "$ip" != "$SERVER_IP" ]]; then
    echo "  ⚠ $d → $ip (kutilgan: $SERVER_IP)"
    ok=0
  else
    echo "  ✓ $d → $ip"
  fi
done

if [[ $ok -eq 0 ]]; then
  echo
  echo "✗ Avval hamma domenlarni ${SERVER_IP} ga yo'naltiring."
  echo "  Keyin qayta urinib ko'ring:"
  echo "    bash deploy/dokploy/setup-dokploy-proxy.sh"
  exit 1
fi

# ── 2) SSL sertifikatini yangilash (dokploy.notiqlik.uz qo'shilgan holda) ──
echo
echo "▶ 2) SSL sertifikati olinmoqda (dokploy.notiqlik.uz qo'shilgan holda)…"

DOMAIN_ARGS=()
for d in "${DOMAINS[@]}"; do DOMAIN_ARGS+=(-d "$d"); done

certbot certonly --webroot \
  -w ./deploy/nginx/certbot/www \
  "${DOMAIN_ARGS[@]}" \
  --cert-name notiqai \
  --non-interactive --agree-tos -m "$EMAIL" \
  --force-renewal

# ── 3) SSL server bloklarini yoqish ──
echo
echo "▶ 3) SSL server bloklari yoqilmoqda…"
cp deploy/nginx/conf.d-ssl/*.conf deploy/nginx/conf.d/
# HTTP bloklar endi kerak emas (HTTPS bloklari o'zlari 80-portda redirect qiladi).
rm -f deploy/nginx/conf.d/00-landing.conf \
      deploy/nginx/conf.d/10-admin.conf \
      deploy/nginx/conf.d/20-curator.conf \
      deploy/nginx/conf.d/30-api.conf

# ── 4) Nginx va boshqa servislarni yangilash ──
echo
echo "▶ 4) Docker image'lar rebuild qilinmoqda…"
docker compose -f docker-compose.deploy.yml build nginx
docker compose -f docker-compose.deploy.yml up -d nginx

# ── 5) Tekshirish ──
echo
echo "▶ 5) Tekshirilmoqda…"
sleep 3

echo
echo "  Nginx health:"
docker exec notiq_nginx wget -qO- http://127.0.0.1/health || echo "  ✗ nginx ishlamayapti"

echo
echo "  Dokploy proxy (host'dan):"
if curl -fsS -o /dev/null -w "    HTTP %{http_code} → %{redirect_url}\n" \
   http://dokploy.notiqlik.uz/ 2>/dev/null; then
  :
else
  echo "  ⚠ Dokploy'ga to'g'ridan-to'g'ri curl bilan ulanib bo'lmadi."
  echo "    Ehtimol Dokploy hali ishga tushmagan. Quyidagini tekshiring:"
  echo "    ss -tlnp | grep :3000"
  echo "    docker logs \$(docker ps --filter 'ancestor=dokploy/dokploy' -q | head -1) 2>/dev/null | tail -20"
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  ✓ Tayyor!"
echo "════════════════════════════════════════════════════════════"
echo "  https://notiqlik.uz"
echo "  https://admin.notiqlik.uz"
echo "  https://curator.notiqlik.uz"
echo "  https://api.notiqlik.uz/docs"
echo "  https://dokploy.notiqlik.uz       ← YANGI"
echo "════════════════════════════════════════════════════════════"
