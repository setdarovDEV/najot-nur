#!/usr/bin/env bash
# NotiqAI — Cloudflare Tunnel starter
# Usages:
#   ./scripts/start-tunnel.sh              → quick free tunnel (URL changes on restart)
#   ./scripts/start-tunnel.sh my-tunnel    → named permanent tunnel (requires `cloudflared tunnel login` first)

set -euo pipefail

PORT=8000
TUNNEL_NAME="${1:-}"
APP_CONSTANTS="mobile/lib/core/constants/app_constants.dart"
LOGFILE="/tmp/cloudflared.log"

cd "$(dirname "$0")/.."

if ! command -v cloudflared &>/dev/null; then
  echo "ERROR: cloudflared not installed."
  echo "Run: sudo dpkg -i /home/abbbose/.claude/jobs/865a5310/tmp/cloudflared.deb"
  exit 1
fi

# ── Named permanent tunnel ───────────────────────────────────────────────────
if [[ -n "$TUNNEL_NAME" ]]; then
  echo "==> Setting up named tunnel: $TUNNEL_NAME"
  echo "    (Requires: cloudflared tunnel login + a domain on Cloudflare)"

  # Create tunnel if it doesn't exist
  if ! cloudflared tunnel list 2>/dev/null | grep -q "$TUNNEL_NAME"; then
    cloudflared tunnel create "$TUNNEL_NAME"
  fi

  # Write tunnel config
  TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | grep "$TUNNEL_NAME" | awk '{print $1}')
  CONFIG_DIR="$HOME/.cloudflared"
  cat > "$CONFIG_DIR/${TUNNEL_NAME}.yml" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json
ingress:
  - service: http://localhost:$PORT
EOF

  echo ""
  echo "==> To create DNS record (replace 'yourdomain.com'):"
  echo "    cloudflared tunnel route dns $TUNNEL_NAME api.yourdomain.com"
  echo ""
  echo "    Then update TUNNEL_HOSTNAME below and re-run with --hostname flag."
  echo ""
  cloudflared tunnel --config "$CONFIG_DIR/${TUNNEL_NAME}.yml" run "$TUNNEL_NAME"

# ── Quick free tunnel (trycloudflare.com) ────────────────────────────────────
else
  echo "==> Starting quick tunnel on localhost:$PORT ..."
  echo "    URL will appear below. Copy it and run:"
  echo "    ./scripts/start-tunnel.sh <tunnel-name>  for a permanent URL."
  echo ""

  # Start tunnel and capture URL
  cloudflared tunnel --url "http://localhost:$PORT" --logfile "$LOGFILE" &
  CF_PID=$!

  # Wait for URL to appear in log
  URL=""
  for i in $(seq 1 30); do
    sleep 1
    URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOGFILE" 2>/dev/null | head -1 || true)
    if [[ -n "$URL" ]]; then break; fi
  done

  if [[ -z "$URL" ]]; then
    echo "ERROR: Could not get tunnel URL. Check $LOGFILE"
    kill $CF_PID 2>/dev/null || true
    exit 1
  fi

  echo ""
  echo "============================================"
  echo "  Tunnel URL: $URL"
  echo "  API URL:    $URL/api/v1"
  echo "============================================"
  echo ""

  # Auto-update app_constants.dart
  API_URL="$URL/api/v1"
  if [[ -f "$APP_CONSTANTS" ]]; then
    sed -i "s|defaultValue: '.*'|defaultValue: '$API_URL'|" "$APP_CONSTANTS"
    echo "==> Updated $APP_CONSTANTS with new URL"
    echo "    Run: flutter build apk --release"
    echo "         (in mobile/ directory)"
  fi

  echo ""
  echo "Press Ctrl+C to stop the tunnel."
  wait $CF_PID
fi
