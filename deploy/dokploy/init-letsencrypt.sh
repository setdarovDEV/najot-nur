#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NotiqAI — Issue Let's Encrypt certificates (run once).
#
#  Prerequisite:
#    DNS A-records for notiqlik.uz, www.notiqlik.uz,
#    admin.notiqlik.uz, curator.notiqlik.uz, api.notiqlik.uz,
#    dokploy.notiqlik.uz
#    must all point to this server's public IP.
#
#  Usage:
#    docker compose -f docker-compose.deploy.yml --profile ssl \
#        run --rm certbot init \
#        notiqlik.uz www.notiqlik.uz admin.notiqlik.uz \
#        curator.notiqlik.uz api.notiqlik.uz dokploy.notiqlik.uz
# ─────────────────────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/../.."

DOMAINS=(
    notiqlik.uz
    www.notiqlik.uz
    admin.notiqlik.uz
    curator.notiqlik.uz
    api.notiqlik.uz
    dokploy.notiqlik.uz
)
EMAIL="${SSL_EMAIL:-admin@notiqlik.uz}"

echo "──────────────────────────────────────────────"
echo "  NotiqAI — Let's Encrypt initial issuance"
echo "──────────────────────────────────────────────"
echo "• Email: ${EMAIL}"
echo "• Domains:"
for d in "${DOMAINS[@]}"; do echo "    - ${d}"; done

# Build certbot -d arguments
DOMAIN_ARGS=()
for d in "${DOMAINS[@]}"; do DOMAIN_ARGS+=(-d "$d"); done

docker compose -f docker-compose.deploy.yml --profile ssl run --rm certbot \
    certonly --webroot \
    -w /var/www/certbot \
    "${DOMAIN_ARGS[@]}" \
    --cert-name notiqai \
    --non-interactive --agree-tos -m "${EMAIL}"

echo
echo "✓ Certificates issued."
echo "  Restart nginx to pick them up:"
echo "    docker compose -f docker-compose.deploy.yml restart nginx"
echo "──────────────────────────────────────────────"
