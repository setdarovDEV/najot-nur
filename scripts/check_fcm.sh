#!/usr/bin/env bash
# scripts/check_fcm.sh
# Diagnose FCM (push notification) configuration across the monorepo.
#
# Usage:  bash scripts/check_fcm.sh
#
# Verifies:
#   1. Backend FCM env vars are set correctly
#   2. firebase-service-account.json is in place
#   3. firebase-admin Python package is installed
#   4. Mobile google-services.json (Android) is a real config, not placeholder
#   5. Mobile GoogleService-Info.plist (iOS) is a real config, not placeholder
#   6. firebase_messaging / firebase_core Flutter packages are declared

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

bold() { printf "\n\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "🔔 FCM (Firebase Cloud Messaging) holati"

# 1. Backend env
bold "1. Backend .env sozlamalari"
if [[ -f "$ENV_FILE" ]]; then
  fcm_enabled=$(grep -E "^FCM_ENABLED" "$ENV_FILE" | cut -d= -f2 | tr -d '"' || echo "")
  sa_path=$(grep -E "^FCM_SERVICE_ACCOUNT_PATH" "$ENV_FILE" | cut -d= -f2 | tr -d '"' || echo "")
  if [[ "$fcm_enabled" == "true" ]]; then
    ok "FCM_ENABLED=true"
  else
    warn "FCM_ENABLED=${fcm_enabled:-false}. Push'lar faqat DB'ga yoziladi, qurilmaga BORMAYDI."
  fi
  echo "  FCM_SERVICE_ACCOUNT_PATH=${sa_path:-./secrets/firebase-service-account.json}"
else
  warn ".env topilmadi ($ENV_FILE)"
fi

# 2. Service account JSON
bold "2. Firebase service account JSON (backend uchun)"
sa_file="$ROOT_DIR/backend/${sa_path:-./secrets/firebase-service-account.json}"
sa_file="${sa_file//\/\.\//\/}"
if [[ -f "$sa_file" ]]; then
  ok "Service account JSON mavjud: $sa_file"
  if grep -q "private_key" "$sa_file" 2>/dev/null; then
    ok "private_key maydoni topildi (real hisobga tegishli ko'rinadi)"
  else
    warn "private_key topilmadi — fayl to'g'ri formatda emas"
  fi
else
  err "Service account JSON TOPILMADI: $sa_file"
  echo "  → Firebase konsoli → Project Settings → Service Accounts →"
  echo "    'Generate new private key' tugmasini bosing va shu joyga saqlang."
fi

# 3. firebase-admin
bold "3. firebase-admin Python paketi"
if [[ -d "$ROOT_DIR/backend/venv" ]]; then
  if "$ROOT_DIR/backend/venv/bin/python" -c "import firebase_admin" 2>/dev/null; then
    ver=$("$ROOT_DIR/backend/venv/bin/python" -c "import firebase_admin; print(firebase_admin.__version__)" 2>/dev/null || echo "?")
    ok "firebase-admin o'rnatilgan (v$ver)"
  else
    err "firebase-admin o'rnatilmagan — pip install firebase-admin"
  fi
else
  warn "backend/venv topilmadi, python tekshiruvi o'tkazib yuborildi"
fi

# 4. Android google-services.json
bold "4. mobile/android/app/google-services.json (Android)"
gs="$ROOT_DIR/mobile/android/app/google-services.json"
if [[ -f "$gs" ]]; then
  if grep -q "REPLACE-ME\|000000000000" "$gs" 2>/dev/null; then
    err "google-services.json PLACEHOLDER ko'rinishida — haqiqiy Firebase konfiguratsiyasi kerak."
    echo "  → Firebase konsoli → Project Settings → 'Add app' → Android →"
    echo "    package_name: uz.najotnur.notiqai  bo'yicha yuklab oling."
  else
    ok "google-services.json haqiqiy konfiguratsiya ko'rinishida"
  fi
else
  err "google-services.json topilmadi: $gs"
fi

# 5. iOS GoogleService-Info.plist
bold "5. mobile/ios/Runner/GoogleService-Info.plist (iOS)"
gs_ios="$ROOT_DIR/mobile/ios/Runner/GoogleService-Info.plist"
if [[ -f "$gs_ios" ]]; then
  if grep -q "REPLACE-ME" "$gs_ios" 2>/dev/null; then
    err "GoogleService-Info.plist PLACEHOLDER — haqiqiy Firebase konfiguratsiyasi kerak."
    echo "  → Firebase konsoli → Project Settings → 'Add app' → iOS →"
    echo "    Bundle ID bo'yicha yuklab oling va shu faylni almashtiring."
  else
    ok "GoogleService-Info.plist haqiqiy konfiguratsiya ko'rinishida"
  fi
else
  err "GoogleService-Info.plist topilmadi: $gs_ios"
fi

# 6. Flutter packages
bold "6. Flutter Firebase paketlari (pubspec.yaml)"
if grep -q "firebase_core" "$ROOT_DIR/mobile/pubspec.yaml"; then
  ok "firebase_core e'lon qilingan"
else
  err "firebase_core pubspec.yaml'da yo'q"
fi
if grep -q "firebase_messaging" "$ROOT_DIR/mobile/pubspec.yaml"; then
  ok "firebase_messaging e'lon qilingan"
else
  err "firebase_messaging pubspec.yaml'da yo'q"
fi

bold "📋 Xulosa"
echo "  • FCM qurilmaga yetib borishi uchun 3 ta narsa kerak:"
echo "    1) Firebase loyiha yaratish (firebase.google.com)"
echo "    2) Service account JSON'ni backend/secrets/ ga qo'yish + FCM_ENABLED=true"
echo "    3) google-services.json (Android) va GoogleService-Info.plist (iOS)"
echo "       — haqiqiy konfiguratsiya bilan almashtirish"
echo ""
echo "  Batafsil: docs/FCM_SETUP.md"
