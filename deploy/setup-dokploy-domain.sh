#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — Dokploy panel uchun dokploy.notiqlik.uz domenini
#  sozlash skripti. SERVERDA root sifatida ishga tushiring.
#
#  Bu skript:
#    1) DNS tekshiradi (dokploy.notiqlik.uz → SERVER_IP ga qaraganmi)
#    2) Dokploy konteynerini topadi
#    3) Dokploy'ning o'zining domain sozlash mexanizmini ishlatadi
#       (settings.updateWebServerServiceDomain yoki shunga o'xshash)
#
#  SSH orqali: ssh notiqai "bash <(cat setup-dokploy-domain.sh)"
# ════════════════════════════════════════════════════════════════
set -e

DOMAIN="${DOKPLOY_DOMAIN:-dokploy.notiqlik.uz}"
SERVER_IP="${SERVER_IP:-45.138.159.219}"
DOKPLOY_PORT="${DOKPLOY_PORT:-3000}"
DOKPLOY_URL="http://127.0.0.1:${DOKPLOY_PORT}"

echo "════════════════════════════════════════════════════════"
echo "  Dokploy panel domenini sozlash: $DOMAIN"
echo "════════════════════════════════════════════════════════"

# ── 1) DNS ────────────────────────────────────────────────
echo
echo "▶ 1) DNS tekshirilmoqda..."
ip=$(dig +short "$DOMAIN" @8.8.8.8 | head -1)
if [[ -z "$ip" ]]; then
    echo "  ✗ DNS topilmadi. Avval A-record qo'shing:"
    echo "    $DOMAIN → $SERVER_IP"
    exit 1
elif [[ "$ip" != "$SERVER_IP" ]]; then
    echo "  ✗ $DOMAIN → $ip (kutilgan: $SERVER_IP)"
    exit 1
else
    echo "  ✓ $DOMAIN → $ip"
fi

# ── 2) Dokploy ishlayaptimi? ─────────────────────────────
echo
echo "▶ 2) Dokploy holati..."
if ! curl -fsS -o /dev/null -m 5 "${DOKPLOY_URL}/api/auth/ok"; then
    echo "  ✗ Dokploy ${DOKPLOY_PORT} da javob bermayapti"
    exit 1
fi
echo "  ✓ Dokploy ishlayapti"

# ── 3) Dokploy konteynerini topish ──────────────────────
echo
echo "▶ 3) Dokploy konteynerini qidiryapman..."
DOKPLOY_CONTAINER=$(docker ps --format '{{.Names}}' | grep -iE 'dokploy' | head -1)
if [[ -z "$DOKPLOY_CONTAINER" ]]; then
    echo "  ✗ Dokploy konteyner topilmadi"
    docker ps --format 'table {{.Names}}\t{{.Image}}'
    exit 1
fi
echo "  ✓ Topildi: $DOKPLOY_CONTAINER"

# ── 4) Traefik konfiguratsiyasini tekshirish ────────────
echo
echo "▶ 4) Traefik konfiguratsiyasi..."
TRAEFIK_CONTAINER=$(docker ps --format '{{.Names}}' | grep -iE 'traefik' | head -1)
if [[ -n "$TRAEFIK_CONTAINER" ]]; then
    echo "  ✓ Traefik konteyner: $TRAEFIK_CONTAINER"
    docker exec "$TRAEFIK_CONTAINER" cat /etc/traefik/dynamic/dokploy.yml 2>/dev/null \
        | grep -A2 "Host(\`$DOMAIN\`)" \
        && echo "  ✓ $DOMAIN Traefik'da allaqachon sozlangan" \
        && exit 0
else
    echo "  ⚠ Traefik konteyner topilmadi (Dokploy'ning ichida bo'lishi mumkin)"
fi

# ── 5) Dokploy API orqali urinish ───────────────────────
echo
echo "▶ 5) Dokploy API orqali domen qo'shish..."
echo
cat <<'EOF'
  ┌──────────────────────────────────────────────────────────┐
  │  Muhim: API login buzilgan bo'lishi mumkin (Dokploy      │
  │  email validator xatosi). Quyidagilardan birini qiling:  │
  └──────────────────────────────────────────────────────────┘

  >>> VARIANT A: Browser orqali (eng oson, 30 soniya) <<<

    1. Brauzerda oching:  http://45.138.159.219:3000
    2. Login qiling
    3. Settings → Web Server → Domain maydoniga
       "dokploy.notiqlik.uz" yozing → Save
    4. 1-2 daqiqa kuting (Let's Encrypt)

  >>> VARIANT B: API orqali (cookie kerak) <<<

    # 1) Cookie olish (browser DevTools → Network → cookie)
    COOKIE="better-auth.session_token=...;"

    # 2) Domain o'rnatish
    curl -X POST http://45.138.159.219:3000/api/settings.update \
      -H "Cookie: $COOKIE" \
      -H "Content-Type: application/json" \
      -d "{\"webServerDomain\":\"$DOMAIN\"}"

  >>> VARIANT C: Traefik static config orqali <<<

    # Dokploy'ning o'zining Traefik dynamic config'ga qo'lda
    # router qo'shish. Buni faqat Dokploy o'zi boshqaradi,
    # shuning uchun o'rniga Variant A tavsiya etiladi.

EOF

# ── 6) Yakuniy tekshirish ───────────────────────────────
echo
echo "▶ 6) HTTPS tekshirish (30 soniya kuting)..."
sleep 30
for i in {1..5}; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" -m 5 "https://${DOMAIN}" 2>/dev/null || echo "000")
    echo "  urinish $i: HTTP $code"
    if [[ "$code" == "200" || "$code" == "302" || "$code" == "301" ]]; then
        echo
        echo "════════════════════════════════════════"
        echo "  ✓ TAYYOR: https://${DOMAIN}"
        echo "════════════════════════════════════════"
        exit 0
    fi
    sleep 10
done

echo
echo "  ⚗ HTTPS hali tayyor emas. Bir necha daqiqadan keyin qayta urinib ko'ring:"
echo "    curl -I https://${DOMAIN}"
