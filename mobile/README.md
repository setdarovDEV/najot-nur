# NotiqAI — Mobile (Flutter)

Najot Nur notiqlik mahorati ilovasi. Premium dizayn, brand `#8A1538`.

## Stack
- **Flutter** (Material 3), **Riverpod** (state), **go_router** (routing)
- **dio** (network), **shared_preferences** (token), **google_fonts** (Manrope ≈ Neue Haas)

## Struktura
```
lib/
├── main.dart · app.dart
├── core/        theme (ranglar, tema), router, network (dio + token), constants
├── models/      user, speech, observation, learning modellar
├── data/        repozitoriylar (auth, speech, observation, learning)
├── providers/   Riverpod providerlar (auth controller, FutureProviderlar)
├── features/
│   ├── onboarding/   3 ta info ekran + Keyingi
│   ├── home/         bottom-nav: Asosiy / Darslar / Kitoblar / Profil
│   ├── auth/         usul tanlash + telefon OTP
│   ├── speech/       hub → Ovoz (qizil belgilash) · Nutq (parazit so'z tahlili)
│   ├── observation/  10 test + tahlil
│   ├── courses/      kurs tafsiloti + darslar
│   └── audiobooks/   Mutolaa uslubidagi o'qish ekrani
└── shared/widgets/   brand logo, ScoreRing, login-gate, common
```

## Ishga tushirish
```bash
flutter pub get

# Backend manzilini bering (Android emulyator host = 10.0.2.2):
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1
# Haqiqiy qurilma uchun kompyuteringiz IP'sini bering, masalan:
# flutter run --dart-define=API_URL=http://192.168.1.10:8000/api/v1
```

## Asosiy oqimlar
- **Mehmon rejimi:** onboarding → bosh sahifa → nutq/ovoz/kuzatuvchanlik testlarini sinab ko'rish mumkin.
- **Gating:** natijani ko'rish uchun ro'yxatdan o'tish so'raladi (`showLoginRequiredSheet`).
- **Ovoz tahlili:** matn o'qiladi → AI xato so'zlarni **qizil** rangda ko'rsatadi (`word_errors` → index bo'yicha belgilash).
- **Nutq tahlili:** parazit so'z, ravonlik, ma'no balansi + xulosa.

## Eslatma (keyingi bosqich)
- Ovoz yozish + STT: hozir `RecordButton` UX'ni boshqaradi va matn tahrirlanadi
  (etalon STT chiqishi sifatida). `record` + STT plaginini ulash — keyingi qadam.
- Google/Telegram tugmalari tayyor; OAuth client sozlamasi qo'shilishi kerak.
- Video pleer (`video_player`) va audio pleer (`just_audio`) UI joylari tayyor.
