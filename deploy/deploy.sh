#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  NotiqAI — birinchi marta sozlash (eski setup-server.sh ga mos).
#  Bu endi setup-server.sh ga delegate qiladi.
# ════════════════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/setup-server.sh" "$@"
