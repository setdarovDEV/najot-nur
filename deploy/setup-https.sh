#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — one-shot HTTPS setup. Run AFTER DNS is configured.
#
#  Prerequisite: 5 A-records must resolve to 45.138.159.219:
#    notiqlik.uz, www.notiqlik.uz, admin.notiqlik.uz,
#    curator.notiqlik.uz, api.notiqlik.uz
# ════════════════════════════════════════════════════════════════
set -euo pipefail

cd "$(dirname "$0")/.."

DOMAINS=(notiqlik.uz www.notiqlik.uz admin.notiqlik.uz curator.notiqlik.uz api.notiqlik.uz)
EMAIL="admin@notiqlik.uz"

# ── 1) DNS tekshirish ──
echo "• DNS tekshirilmoqda…"
ok=1
for d in "${DOMAINS[@]}"; do
  ip=$(dig +short "$d" @8.8.8.8 | head -1)
  if [[ -z "$ip" ]]; then
    echo "  ✗ $d → DNS topilmadi"
    ok=0
  elif [[ "$ip" != "45.138.159.219" ]]; then
    echo "  ⚠ $d → $ip (kutilgan: 45.138.159.219)"
    ok=0
  else
    echo "  ✓ $d → $ip"
  fi
done
if [[ $ok -eq 0 ]]; then
  echo
  echo "✗ Barcha domenlar 45.138.159.219 ga yo'naltirilmagan."
  echo "  Registrar paneldan A yozuvlarni qo'shing, so'ng qayta urinib ko'ring."
  exit 1
fi

# ── 2) Let's Encrypt sert olish ──
echo
echo "• Let's Encrypt sertifikati olinmoqda…"
certbot certonly --webroot \
  -w ./deploy/nginx/certbot/www \
  -d notiqlik.uz -d www.notiqlik.uz \
  -d admin.notiqlik.uz -d curator.notiqlik.uz -d api.notiqlik.uz \
  --cert-name notiqai \
  --non-interactive --agree-tos -m "$EMAIL"

# ── 3) SSL konfiguratsiyani yoqish ──
echo
echo "• SSL server bloklari yoqilmoqda…"
cp deploy/nginx/conf.d-ssl/*.conf deploy/nginx/conf.d/
# Eski HTTP konfiguratsiyalar endi redirect qiladi, lekin 80-portda
# to'g'ridan-to'g'ri eski serverlar ham bor. Ularni o'chirib qo'yamiz
# (HTTPS bloklari o'zlari 80-portda redirect qiladi).
rm -f deploy/nginx/conf.d/00-landing.conf \
      deploy/nginx/conf.d/10-admin.conf \
      deploy/nginx/conf.d/20-curator.conf \
      deploy/nginx/conf.d/30-api.conf

# ── 4) Nginx reload ──
echo
echo "• Nginx qayta yuklanmoqda…"
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx

# ── 5) Avtomatik yangilash ──
echo
echo "• Sert avtomatik yangilash sozlanmoqda…"
( crontab -l 2>/dev/null | grep -v 'certbot renew' ; \
  echo "0 3 * * * certbot renew --quiet --deploy-hook 'docker compose -f /opt/notiqai/docker-compose.yml -f /opt/notiqai/docker-compose.prod.yml restart nginx' > /var/log/certbot-renew.log 2>&1" ) | crontab -

echo
echo "════════════════════════════════════════════"
echo "  ✓ HTTPS yoqildi!"
echo "════════════════════════════════════════════"
echo "  https://notiqlik.uz"
echo "  https://admin.notiqlik.uz"
echo "  https://curator.notiqlik.uz"
echo "  https://api.notiqlik.uz/docs"
echo "════════════════════════════════════════════"
