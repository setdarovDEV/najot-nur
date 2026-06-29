# Push Notifications (FCM) — Toʻliq sozlash qoʻllanmasi

NotiqAI ilovasida push bildirishnomalar **Firebase Cloud Messaging (FCM)**
orqali yuboriladi. Admin panelda "Hammaga / Kursga / Foydalanuvchiga"
yuborilgan xabarlar toʻgʻri ishlashi uchun quyidagilarni bajarish kerak.

> Tekshiruv skripti: `bash scripts/check_fcm.sh` — qaysi qadam bajarilmaganini
> avtomatik aniqlab beradi.

---

## 0. Umumiy koʻrinish

```
[Admin panel] → POST /api/v1/admin/push
        ↓
[Backend FastAPI] → DB'ga yozadi + Firebase Admin SDK orqali yuboradi
        ↓
[FCM servers] → qabul qiladi va qurilmalarga tarqatadi
        ↓
[Android/iOS qurilma] → lock screen / notification tray'da ko'rinadi
```

**Muhim:** Hozircha loyiha "degraded mode"da — backend xabarni DB'ga yozadi,
lekin qurilmaga yetkazmaydi, chunki Firebase sozlanmagan.

---

## 1. Firebase loyiha yaratish (5 daqiqa)

1. <https://console.firebase.google.com> ga kiring
2. **"Add project"** → nom: `notiqai-prod` (yoki xohlagan nom) → davom eting
3. Google Analytics kerak emas, oʻchirib qoʻyishingiz mumkin → **Create project**

---

## 2. Android ilovani roʻyxatdan oʻtkazish

1. Firebase konsolida **Project Settings** (⚙️) → **General**
2. **"Your apps"** boʻlimida **Android** belgisini bosing
3. Maʻlumotlarni toʻldiring:
   - **Android package name:** `uz.najotnur.notiqai` (pubspec.yaml'da `name: notiqai`,
     lekin Android `applicationId` `uz.najotnur.notiqai` — `android/app/build.gradle.kts`'da koʻrinadi)
   - App nickname: `NotiqAI Android`
   - Debug signing certificate SHA-1: hozircha boʻsh qoldiring
4. **Register app** → **Download google-services.json**
5. Yuklab olingan faylni **`mobile/android/app/google-services.json`** ga
   ustidan yozing (hozirgi placeholder'ni almashtirasiz)
6. `mobile/android/build.gradle.kts` da `google-services` plagini yoqilganini
   tekshiring (loyihada allaqachon qoʻshilgan boʻlishi kerak)

---

## 3. iOS ilovani roʻyxatdan oʻtkazish

1. **Project Settings** → **"Your apps"** → **iOS** belgisini bosing
2. Maʻlumotlarni toʻldiring:
   - **iOS bundle ID:** `uz.najotnur.notiqai` (yoki `ios/Runner.xcodeproj`'dagi
     `PRODUCT_BUNDLE_IDENTIFIER` bilan bir xil)
   - App nickname: `NotiqAI iOS`
3. **Register app** → **Download GoogleService-Info.plist**
4. Yuklab olingan faylni **`mobile/ios/Runner/GoogleService-Info.plist`** ga
   ustidan yozing
5. Xcode'da `Runner.xcworkspace` oching → chap paneldan `Runner` tanlang →
   Build Phases → Copy Bundle Resources → fayl mavjudligini tasdiqlang
6. `cd mobile/ios && pod install` (agar hali qilinmagan boʻlsa)

> Hozircha iOS uchun placeholder yozilgan. Uni albatta haqiqiy konfiguratsiya
> bilan almashtirish kerak — aks holda iOS qurilmalar hech qachon push
> qabul qilmaydi.

---

## 4. Backend service account JSON

Bu — backend'ning FCM'ga ulanishi uchun kerak boʻlgan kalit.

1. Firebase konsolida **Project Settings** → **Service Accounts** tab
2. **"Generate new private key"** tugmasini bosing → JSON yuklab olinadi
3. JSON faylni **`backend/secrets/firebase-service-account.json`** ga saqlang
   (papka mavjud, hozircha boʻsh)

> ⚠️ Bu fayl **maxfiy** — hech qachon git'ga commit qilmang! Loyihada allaqachon
> `.gitignore` orqali himoyalangan, lekin ehtiyot boʻling.

---

## 5. .env faylini yangilash

`backend/.env` (yoki ildiz `.env`) faylida quyidagilarni sozlang:

```bash
# FCM yoqish
FCM_ENABLED=true
FCM_SERVICE_ACCOUNT_PATH=./secrets/firebase-service-account.json
FCM_PROJECT_ID=notiqai-prod   # Firebase project ID (konsoldan oling)
```

> `FCM_PROJECT_ID` ixtiyoriy — Firebase'dan avtomatik aniqlanadi, lekin
> aniq koʻrsatish yaxshi.

---

## 6. Migratsiyalar va restart

```bash
# Yangi migratsiyalar (agar kerak bo'lsa)
cd backend && alembic upgrade head

# Backend'ni qayta ishga tushirish
# Docker bo'lsa:
docker compose restart backend
# Yoki to'g'ridan-to'g'ri:
uvicorn app.main:app --reload
```

---

## 7. Tekshirish (3 usul)

### 7.1. CLI diagnostika

```bash
bash scripts/check_fcm.sh
```

Skript barcha 6 ta qadamni tekshirib, qaysi biri bajarilmaganligini aniq
koʻrsatadi.

### 7.2. Admin panel — FCM status

Admin panel → **Bildirishnomalar** sahifasida endi tepada **FCM holati** koʻrsatiladi:

- ✅ **Tayyor** — hammasi toʻgʻri, push ishlaydi
- ⚠️ **Sozlanmagan** — qaysi qadam bajarilmaganini aniq koʻrsatadi

### 7.3. Test push

Admin panel → **Bildirishnomalar** → pastdagi **"Test push yuborish"**
tugmasi. Bu sizning oʻzingizning qurilmangizga test xabar yuboradi
(token roʻyxatdan oʻtgan boʻlishi kerak).

### 7.4. Backend'dan toʻgʻridan-toʻgʻri

```bash
# FCM status
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8000/api/v1/admin/push/status

# Mening tokenlarim (token ro'yxatdan o'tganmi?)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8000/api/v1/users/me/push-tokens
```

---

## 8. Mobile ilovada token roʻyxatdan oʻtishi

`lib/services/push_service.dart` quyidagilarni avtomatik bajaradi:

1. `Firebase.initializeApp()` — Firebase'ni ishga tushiradi
2. `requestPermission()` — foydalanuvchidan ruxsat soʻraydi
3. `getToken()` — FCM token oladi
4. `POST /users/me/push-token` — backend'ga roʻyxatdan oʻtkazadi
5. `onTokenRefresh` — token yangilanganda qayta roʻyxatdan oʻtkazadi
6. `onMessage` — foreground'da local notification koʻrsatadi
7. `onMessageOpenedApp` — background'dan ochilganda ishlov beradi
8. `onBackgroundMessage` — butunlay yopiq boʻlganda ham qabul qiladi

Tabriklayman! Hammasi toʻgʻri sozlangan boʻlsa, admin panel'dan
"Hammaga yuborish" bosilganda **barcha foydalanuvchilarning qurilmalariga
lock screen / notification tray orqali** xabar keladi.

---

## 9. Muammolarni hal qilish

### ❌ "Push DB'ga yozildi, lekin qurilmaga kelmayapti"

1. `bash scripts/check_fcm.sh` — qaysi qadamda muammo borligini koʻrsatadi
2. `.env` da `FCM_ENABLED=true` ekanligini tasdiqlang
3. `backend/secrets/firebase-service-account.json` haqiqiy hisobga tegishlimi?
4. Foydalanuvchi ilovaga kirganmi? (Login boʻlmasa token roʻyxatdan oʻtmaydi)
5. Ilovada ruxsat berilganmi? (iOS Settings → NotiqAI → Notifications)

### ❌ "iOS push kelmayapti, Android ishlayapti"

- `GoogleService-Info.plist` placeholder ehtimol — haqiqiy Firebase
  konfiguratsiyasi bilan almashtiring
- Xcode'da Signing & Capabilities → Push Notifications qoʻshilganmi?
- `pod install` qildingizmi?

### ❌ "Xato: messaging/registration-token-not-registered"

Eski yoki notoʻgʻri token. FCM oʻzi avtomatik tozalaydi (server-side pruning)
— keyingi push'lar toʻgʻri ishlaydi.

### ❌ Android 13+ da ruxsat soʻramasa

Android 13 dan boshlab `POST_NOTIFICATIONS` runtime permission kerak.
`AndroidManifest.xml` da allaqachon bor (`push_service.dart` soʻraydi), lekin
foydalanuvchi rad etgan boʻlsa — ilova sozlamalaridan yoqish kerak.

---

## 10. FCM narxi va limitlar

- **Bepul kvota:** 10 million xabar/oy (Spark plan) — bizning loyiha uchun
  yetarli
- **Hech qanday toʻlov talab qilinmaydi** agar xabar matni va maʼlumotlari
  4KB dan oshmasa
- Limit oshsa Firebase avtomatik xabar beradi

---

## Xulosa

Barcha 5 ta qadam bajarilgach:

1. ✅ Firebase loyiha yaratildi
2. ✅ Android `google-services.json` haqiqiy
3. ✅ iOS `GoogleService-Info.plist` haqiqiy
4. ✅ Backend `firebase-service-account.json` joyida
5. ✅ `FCM_ENABLED=true` .env'da

Admin panel'dan yuborilgan har qanday push xabari **foydalanuvchilarning
qurilmasiga SMS koʻrinishida** (lock screen + notification tray) yetib boradi.
Xabarni ochgan foydalanuvchi ilovaga kirib, "Bildirishnomalar" sahifasida
toʻliq tarixni ham koʻradi.
