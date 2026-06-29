#!/bin/bash
# Start a Cloudflare quick tunnel to the local NotiqAI backend (port 8001)
# and print the public URL with a ready-to-use `flutter run` command.
#
# Quick tunnels need no Cloudflare account, but the URL rotates each time
# you (re)start the tunnel. For a stable URL, use a named tunnel
# (see docs/cloudflare.md).

set -e

PORT="${BACKEND_PORT:-8001}"

pkill -f "cloudflared tunnel --url" 2>/dev/null || true
sleep 1
rm -f /tmp/cloudflared.log

nohup cloudflared tunnel --url "http://localhost:$PORT" --no-autoupdate \
  > /tmp/cloudflared.log 2>&1 &
CFD_PID=$!
disown

URL=""
for i in {1..15}; do
  sleep 2
  URL=$(grep -oE "https://[a-z0-9-]+\.trycloudflare\.com" /tmp/cloudflared.log 2>/dev/null | head -1 || true)
  [ -n "$URL" ] && break
done

if [ -z "$URL" ]; then
  echo "Cloudflared did not start in time. Check /tmp/cloudflared.log" >&2
  exit 1
fi

echo ""
echo "Cloudflare tunnel is up (PID $CFD_PID)"
echo "  Public URL : $URL"
echo "  Local port : $PORT"
echo ""
echo "Run mobile app with:"
echo "  flutter run --dart-define=API_URL=$URL/api/v1"
echo ""
