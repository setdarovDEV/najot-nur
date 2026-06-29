# NotiqAI — Xavfsizlik tizimi

Bu hujjat mobil ilovaning **ekran zapish / screen recording himoyasi** va
**login vaqtida identifikatsiya yozuvi** tizimini tushuntiradi.

## 🎯 Imkoniyatlar

| # | Xususiyat | Android | iOS |
|---|-----------|---------|-----|
| 1 | **FLAG_SECURE** — screenshot va screen recording bloklanadi | ✅ | ⚠️ iOS public API yo'q |
| 2 | **Screen capture aniqlash** — recorder yoki AirPlay ulanganda seziladi | ✅ MediaProjection | ✅ `UIScreen.isCaptured` |
| 3 | **Mirror aniqlash** — tashqi displey ulanganda seziladi | ✅ DisplayManager | ✅ `UIScreen.screens` |
| 4 | **Root / Jailbreak signal** | ✅ `Build.TAGS` + `/su` | 🚧 placeholder |
| 5 | **Tiled watermark** — foydalanuvchi identifikatori ekranning ustiga yoziladi | ✅ | ✅ |
| 6 | **Capture overlay** — recording boshlansa qora parda + ogohlantirish banneri | ✅ | ✅ |
| 7 | **Avtomatik 5-soniya audio yozuvi** — login vaqtida identifikatsiya uchun | ✅ | ✅ |
| 8 | **Server-side session tracking** — har sessiya `security_sessions` jadvaliga yoziladi | ✅ | ✅ |
| 9 | **Heartbeat (har 60 s)** — sessiya jonli, watermark rotation | ✅ | ✅ |
| 10 | **Event log** — har bir capture/root/mic-denied hodisasi serverga yuboriladi | ✅ | ✅ |

## 🏗 Arxitektura

```
┌────────────────────────────────────────────────────────────┐
│  Mobile (Flutter)                                          │
│                                                            │
│  AuthController                                            │
│    ├─ onAuthenticated() ───┐                               │
│    └─ logout()             │                               │
│                            ▼                               │
│  SecurityService  ──► SecurityChannel (notiqai/security)   │
│    │                  ├─ Android: MainActivity.kt          │
│    │                  │   (FLAG_SECURE + DisplayManager)   │
│    │                  └─ iOS: AppDelegate.swift            │
│    │                      (UIScreen.capturedDidChange)    │
│    │                                                       │
│    ├─ AudioRecorder  ── 5-sec m4a ── upload               │
│    │                                                       │
│    └─ ValueNotifier<SecurityStatus>                        │
│            │                                               │
│            ▼                                               │
│  SecurityWatermark  (tiled CustomPaint)                    │
│  SecurityCaptureOverlay (ColorFilter + banner)             │
│                                                            │
└────────────────────────────────────────────────────────────┘
                │ HTTPS
                ▼
┌────────────────────────────────────────────────────────────┐
│  Backend (FastAPI)                                         │
│                                                            │
│  /api/v1/security/sessions                                │
│    POST /start         → yangi session, watermark yaratish │
│    POST /:id/heartbeat → watermark rotation                │
│    POST /:id/end       → session yopish                    │
│    POST /:id/events    → capture / root / mic-denied       │
│    POST /:id/recording → 5-sec audio upload                │
│    GET  /              → sessiyalar tarixi                 │
│    GET  /:id           → bitta sessiya + eventlar         │
│                                                            │
│  Tables: security_sessions, security_session_events        │
└────────────────────────────────────────────────────────────┘
```

## 🚀 Ishga tushirish

### 1. Backend migratsiya

```bash
cd backend
source venv/bin/activate
alembic upgrade head
```

Yangi jadvallar:
- `security_sessions` — har login uchun bitta qator
- `security_session_events` — append-only event log

### 2. Flutter paketlar

```bash
cd mobile
flutter pub get
flutter gen-l10n
```

### 3. Android — kamera/mikrofon ruxsati avtomatik

`AndroidManifest.xml` ga `CAMERA`, `RECORD_AUDIO` va
`FOREGROUND_SERVICE_CAMERA` qo'shildi. Runtime ruxsat so'rovi
`Permission.microphone.request()` orqali qilinadi (login vaqtida).

### 4. iOS — Info.plist

`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
`NSPhotoLibraryUsageDescription` qo'shildi.

## 🔒 Xavfsizlik oqimi (timeline)

1. **Foydalanuvchi login qiladi** (parol yoki OTP)
2. `AuthController.onAuthenticated()` chaqiriladi
3. `SecurityService.onLogin(user)`:
   - **Native** `setSecure(true)` → Android: `FLAG_SECURE` o'rnatiladi,
     iOS: capture observer yoqiladi
   - **Server** `/security/sessions/start` → watermark matn yaratiladi
   - **Heartbeat timer** (60 s) boshlanadi
   - **Audio capture** 5 s davom etadi, keyin `/security/sessions/:id/recording` ga yuklanadi
4. Foydalanuvchi ilovada ishlaydi:
   - **Watermark** har 30 s da yangi timestamp bilan qayta chiziladi
   - **Screen capture aniqlansa** → qora parda + qizil banner
5. **Logout** → `/security/sessions/:id/end`

## 📡 Native platform channel

`notiqai/security` method channel — `lib/services/security_channel.dart`.

| Method | Platform | Tavsifi |
|--------|----------|---------|
| `setSecure(enabled)` | Android, iOS | FLAG_SECURE yoqish/o'chirish |
| `isCaptured()` | Android, iOS | Capture yoki mirror aniqlash |
| `isRooted()` | Android | Root/jailbreak signal |
| `isSecure()` | ikkala | Secure holati |
| `getDeviceInfo()` | ikkala | OS, model, platform |
| `onScreenCapturedChanged` (event) | ikkala | Capture boshlanishi/to'xtashi |

## ❌ Nima uchun **mumkin emas** (foydalanuvchi bilishi kerak)

- **Boshqa fizik qurilmaning kamerasi** (telefon, fotoapparat) ekranni
  zapish qilmasligini ta'minlash — bu analog muammo. Bizning ilovamiz
  boshqa qurilmani boshqara olmaydi.
- **Boshqa qurilmada video olinganda ekranni oq qilish** — bu boshqa
  qurilmaning kamerasi, u ekranni "ko'radi", hech qanday dastur bu
  tasvirni o'zgartira olmaydi.

Buning o'rniga biz:
- ✅ **O'z qurilmasida** screenshot/screen recording ni bloklaymiz
  (FLAG_SECURE)
- ✅ **O'z qurilmasida** screen capture aniqlaymiz va qora parda +
  ogohlantirish ko'rsatamiz
- ✅ **Boshqa qurulmaga** foydalanuvchi bergan **audio identifikatsiya**
  yuboramiz (kim login qilganini aniqlash uchun)
- ✅ **Barcha sessiyalar** server tomonida audit log ga yoziladi
  (IP, qurilma modeli, vaqt)

## 🧪 Tekshirish

```bash
# Backend ishlayaptimi?
curl http://localhost:8000/health

# Yangi migratsiya qo'llandi mi?
cd backend && source venv/bin/activate
alembic current
# Oxirgi qator: g7h8i9j0k1l2 (head)

# Flutter analyze
cd mobile && flutter analyze
# 0 error

# Android: FLAG_SECURE ishlashi
adb shell dumpsys window windows | grep -i "notiqai.*secure"
```

## 📁 Yaratilgan / o'zgartirilgan fayllar

### Backend
- `app/models/security_session.py` (yangi)
- `app/models/__init__.py` (export qo'shildi)
- `app/schemas/security.py` (yangi)
- `app/services/security_service.py` (yangi)
- `app/api/v1/security.py` (yangi)
- `app/api/v1/router.py` (security router qo'shildi)
- `alembic/versions/g7h8i9j0k1l2_add_security_sessions.py` (yangi)

### Mobile
- `pubspec.yaml` (permission_handler, device_info_plus, uuid, package_info_plus)
- `android/app/src/main/AndroidManifest.xml` (CAMERA, FOREGROUND_SERVICE_CAMERA)
- `android/app/src/main/kotlin/.../MainActivity.kt` (FLAG_SECURE, platform channel)
- `ios/Runner/Info.plist` (NSCameraUsageDescription, NSPhotoLibraryUsageDescription)
- `ios/Runner/AppDelegate.swift` (capture observer, platform channel)
- `lib/services/security_channel.dart` (yangi)
- `lib/services/security_service.dart` (yangi)
- `lib/data/repositories.dart` (SecurityRepository qo'shildi)
- `lib/providers/providers.dart` (AuthController yangilandi)
- `lib/app.dart` (watermark + capture overlay wrapper)
- `lib/shared/widgets/security_watermark.dart` (yangi)
- `lib/shared/widgets/security_capture_overlay.dart` (yangi)
- `lib/l10n/app_*.arb` (securityCaptureDetected/Subtitle)
