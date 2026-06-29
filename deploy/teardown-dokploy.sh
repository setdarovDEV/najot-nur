#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — Dokploy'ni butunlay o'chirish.
#
#  ⚠ OGOHLANTIRISH: Bu skript Dokploy'ni va uning ma'lumotlarini
#  o'chiradi. Agar boshqa loyihalar Dokploy'da bo'lsa, avval
#  ularni boshqa joyga ko'chiring.
#
#  Bu skript quyidagilarni qiladi:
#    1) notiqai compose project'ni to'xtatadi
#    2) Dokploy konteynerini to'xtatadi va o'chiradi
#    3) Dokploy'ning Traefik va boshqa ichki servislarini o'chiradi
#    4) /etc/dokploy papkasini tozalaydi
#
#  Serverda root bo'lib ishga tushiring:  bash teardown-dokploy.sh
# ════════════════════════════════════════════════════════════════
set -euo pipefail

echo "═══════════════════════════════════════════════════════════"
echo "  ⚠ Dokploy'ni o'chirish"
echo "═══════════════════════════════════════════════════════════"
echo
echo "Bu skript Dokploy'ni to'liq o'chiradi."
echo "Davom etishni xohlaysizmi? (yes/no)"
read -r ans
[[ "$ans" == "yes" ]] || { echo "Bekor qilindi."; exit 1; }

echo
echo "▶ 1) notiqai compose project'ni to'xtatish..."
cd /opt/notiqai 2>/dev/null || true
if [[ -f docker-compose.yml ]]; then
  docker compose -p najotnur-notiqai-notiqai-nqidhb down --remove-orphans 2>/dev/null || \
  docker compose down --remove-orphans 2>/dev/null || true
fi

echo "▶ 2) notiq_ bilan boshlangan konteynerlarni to'xtatish..."
docker ps -a --format '{{.Names}}' | grep -E '^notiq_' | while read -r c; do
  echo "   stop: $c"
  docker stop "$c" 2>/dev/null || true
  docker rm -f "$c" 2>/dev/null || true
done

echo "▶ 3) Dokploy konteynerini topish va o'chirish..."
DOKPLOY_CONTAINERS=$(docker ps -a --format '{{.Names}}' | grep -iE 'dokploy' || true)
if [[ -n "$DOKPLOY_CONTAINERS" ]]; then
  echo "$DOKPLOY_CONTAINERS" | while read -r c; do
    echo "   stop: $c"
    docker stop "$c" 2>/dev/null || true
    docker rm -f "$c" 2>/dev/null || true
  done
fi

echo "▶ 4) Traefik va Dokploy network'larini o'chirish..."
docker network ls --format '{{.Name}}' | grep -iE 'dokploy|traefik' | while read -r n; do
  echo "   remove: $n"
  docker network rm "$n" 2>/dev/null || true
done

echo "▶ 5) Port 80 va 443 bo'shligini tekshirish..."
sleep 2
if ss -tlnp 2>/dev/null | grep -qE ':(80|443)\s'; then
  echo "  ⚠ Hali ham port 80/443 band:"
  ss -tlnp 2>/dev/null | grep -E ':(80|443)\s'
else
  echo "  ✓ Port 80 va 443 bo'sh"
fi

echo "▶ 6) /etc/dokploy papkasini o'chirish (ixtiyoriy)..."
if [[ -d /etc/dokploy ]]; then
  rm -rf /etc/dokploy
  echo "  ✓ /etc/dokploy o'chirildi"
fi

echo
echo "═══════════════════════════════════════════════════════════"
echo "  ✓ Dokploy o'chirildi"
echo "═══════════════════════════════════════════════════════════"
echo
echo "Keyingi qadam:"
echo "  1) bash setup-server.sh        # yangi stack o'rnatish"
echo
