<div align="center">

# NotiqAI — Najot Nur

**Notiqlik mahorati markazi** uchun AI yordamida nutq, ovoz va kuzatuvchanlikni
o'rgatuvchi va baholovchi platforma.

`Flutter` · `FastAPI` · `React + Vite` · `PostgreSQL` · `Redis` · `Docker`

</div>

---

## 🎯 Loyiha haqida

NotiqAI — foydalanuvchining **notiqlik mahoratini** sun'iy intellekt yordamida
mashq qildiradigan va baholaydigan mobil ilova. Foydalanuvchi:

- **Nutqini tekshiradi** — o'zi haqida ~2 daqiqa gapiradi, AI parazit so'zlar
  ("hmm", "aaah", "haligi"), pauzalar, ma'no yetkazilishi va ma'lumot hajmini tahlil qiladi.
- **Ovozini tekshiradi** — berilgan matnni o'qiydi, AI uni etalon bilan solishtiradi
  va xato tovush/so'zlarni **qizil** rangda belgilab, umumiy tahlil beradi.
- **Kuzatuvchanligini tekshiradi** — 10 ta video/rasmli test (psixologiya, tana tili).
- **Video darslar** sotib oladi, har dars yakunida test/AI mashqlar bajaradi.
- **Audiokitoblar** tinglaydi (bepul + sotuvga).

Kuratorlar admin paneldan uy vazifalarini tekshiradi, ball qo'yadi; kursni
tugatganlarga **PDF sertifikat** beriladi.

## 🏗 Arxitektura (monorepo)

```
najot-nur/
├── backend/        FastAPI · SQLAlchemy(async) · Alembic · Redis · Claude AI
├── mobile/         Flutter ilova (premium UI, brand: #8A1538)
├── admin/          React + Vite + TS admin panel (kuratorlar, mijozlar, push)
├── docs/           Brending (logo, ranglar, NN aydentika.pdf)
├── docker-compose.yml
└── .env.example
```

## 🎨 Brending

| Token | Qiymat |
|-------|--------|
| Primary (wine) | `#8A1538` |
| Accent orange  | `#FF5C39` |
| Accent blue    | `#5BC2E7` |
| White          | `#FFFFFF` |
| Shrift         | Neue Haas Grotesk (fallback: Inter) |

## 🚀 Ishga tushirish

```bash
# 1. Env tayyorlash
cp .env.example .env        # qiymatlarni to'ldiring

# 2. Hammasini Docker bilan
docker compose up -d        # postgres + redis + backend + admin

# Backend:  http://localhost:8000/docs   (Swagger / OpenAPI)
# Admin:    http://localhost:5173
```

Har bir qism alohida ham ishga tushadi — `backend/README.md`,
`mobile/README.md`, `admin/README.md` ga qarang.

> **Eslatma:** bu kompyuterda tizim PostgreSQL'i `5432`-portni egallagani uchun
> loyiha bazasi Docker'da `5544`-portga joylangan (`.env` shunga sozlangan).
> Toza muhitda standart `5432` ishlatilaveradi.

## 🔐 Demo hisoblar
| Rol | Login | Parol |
|-----|-------|-------|
| Admin | `admin@najotnur.uz` | `admin123` |
| Kurator | `curator@najotnur.uz` | `curator123` |
| Foydalanuvchi (mobil) | telefon OTP | `DEBUG` rejimda kod javobda qaytadi |

## ✅ Tekshirildi
- Backend: 36 API endpoint, migratsiya + seed, auth (OTP→JWT), RBAC (user→admin = 403),
  ovoz tahlili xato so'zlarni aniqladi (`muhim→muxim` h/x tovushi), gating (anon = 401).
- Mobil: `flutter analyze` — **0 xato**.
- Admin: `tsc` (strict) + `vite build` — **muvaffaqiyatli**.

## 🗺 Yo'l xaritasi

- [x] Backend poydevori, auth, domen modellar, AI tahlil servisi
- [x] Mobil ilova (onboarding, auth, nutq/ovoz/kuzatuvchanlik, darslar, audiokitob)
- [x] Admin panel (mijozlar, kuratorlar, audiokitob, push)
- [ ] To'lovlar: Uzum, Uzum Nasiya, ATMOS
- [ ] AMOCRM lead integratsiyasi (hook tayyor)
- [ ] PDF sertifikat generatsiyasi (servis tayyor, shablon kerak)
