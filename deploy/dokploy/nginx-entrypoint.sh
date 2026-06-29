#!/bin/sh
# ─────────────────────────────────────────────────────────────
#  NotiqAI — Smart nginx entrypoint.
#  POSIX-sh compatible (so it works with the busybox entrypoint
#  that the official nginx:alpine image uses).
#
#  Behaviour at container start:
#    • If /etc/letsencrypt/live/notiqai/fullchain.pem exists
#      → copy conf.d-ssl/*.conf into conf.d/ (HTTPS mode)
#    • Otherwise keep the default conf.d/*.conf (HTTP mode)
# ─────────────────────────────────────────────────────────────

CERT_DIR="/etc/letsencrypt/live/notiqai"
CONF_D="/etc/nginx/conf.d"
CONF_D_SSL="/etc/nginx/conf.d-ssl"

echo "──────────────────────────────────────────────"
echo "  NotiqAI — nginx entrypoint"
echo "──────────────────────────────────────────────"

has_certs=0
if [ -d "/etc/letsencrypt" ] && [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]; then
    has_certs=1
fi

if [ "${has_certs}" = "1" ]; then
    echo ">> SSL certs detected at ${CERT_DIR}"
    echo ">> Activating HTTPS server blocks..."

    # Wipe any default blocks, then install the SSL ones.
    rm -f "${CONF_D}"/*.conf
    cp "${CONF_D_SSL}"/*.conf "${CONF_D}/"

    if [ -f "${CERT_DIR}/chain.pem" ]; then
        echo ">> OCSP chain.pem present (stapling enabled)"
    fi
else
    echo ">> No SSL certs at ${CERT_DIR}"
    echo ">> Running in HTTP-only mode."
    echo "   (Dokploy Traefik / external proxy is expected to"
    echo "    terminate TLS in front of this container.)"
fi

# Quick syntax check before nginx actually starts.
echo ">> Running nginx -t..."
nginx -t

echo ">> Starting nginx..."
echo "──────────────────────────────────────────────"

# The official nginx:alpine entrypoint will pick up here
# and run `nginx -g "daemon off;"`.
exit 0
