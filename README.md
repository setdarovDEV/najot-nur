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

Kuratorlar **curator paneli** orqali uy vazifalarini tekshiradi, ball qo'yadi;
adminlar esa **admin paneli** orqali mijozlar, to'lovlar va kontentni boshqaradi;
kursni tugatganlarga **PDF sertifikat** beriladi.

## 🏗 Arxitektura (monorepo, 4 ta alohida frontend)

```
najot-nur/
├── backend/        FastAPI · SQLAlchemy(async) · Alembic · Redis · Claude AI
├── mobile/         Flutter ilova (premium UI, brand: #8A1538)
├── landing/        React + Vite + TS  → notiqlik.uz         (marketing)
├── admin/          React + Vite + TS  → admin.notiqlik.uz   (super admin panel)
├── curator/        React + Vite + TS  → curator.notiqlik.uz (kurator paneli)
├── docs/           Brending (logo, ranglar, NN aydentika.pdf)
├── deploy/
│   ├── nginx/      Host-based routing konfiguratsiya
│   ├── deploy.sh   Birinchi deploy
│   ├── update.sh   Kod yangilash
│   └── ...
├── docker-compose.production.yml   ← YAGONA production compose
└── .env.production.example
```

### Domenlar (Dokploy Traefik → bitta nginx → Host header routing)

| Domen | Service | Prod | Tavsif |
|-------|---------|------|--------|
| `notiqlik.uz` / `www.notiqlik.uz` | `landing` | 443 | Marketing sahifa |
| `admin.notiqlik.uz` | `admin` | 443 | Super admin paneli |
| `curator.notiqlik.uz` | `curator` | 443 | Kurator paneli |
| `api.notiqlik.uz` | `backend` | 443 | FastAPI API |

Dokploy'da 4 ta domenning **har biri** `nginx` service'ga (port 80)
ulanadi. Nginx `Host` header orqali to'g'ri service'ga yo'naltiradi.

## 🎨 Brending

| Token | Qiymat |
|-------|--------|
| Primary (wine) | `#8A1538` |
| Accent orange  | `#FF5C39` |
| Accent blue    | `#5BC2E7` |
| White          | `#FFFFFF` |
| Shrift         | Neue Haas Grotesk (fallback: Inter) |

## 🚀 Ishga tushirish

### Lokal development

```bash
# 1) Env tayyorlash
cp .env.example .env        # qiymatlarni to'ldiring

# 2) Hammasini Docker bilan
docker compose up -d        # postgres + redis + backend + admin + curator + landing

# Backend:  http://localhost:8000/docs   (Swagger / OpenAPI)
# Landing:  http://localhost:5175
# Admin:    http://localhost:5173
# Curator:  http://localhost:5174
```

### Production (Dokploy / self-hosted) — **bitta komanda**

```bash
# 1) Production env tayyorlash
cp .env.production.example .env
# CHANGE_ME_* larni haqiqiy qiymatlar bilan almashtiring
# (kamida POSTGRES_PASSWORD va JWT_SECRET_KEY)

# 2) Birinchi marta seed ma'lumotlarni yuklash uchun .env ga:
#    RUN_SEEDS=true   ← keyin false qilib qo'ying

# 3) Hamma narsani ishga tushirish
docker compose -f docker-compose.production.yml up -d --build
```

Tafsilotlar: **[deploy/README.md](deploy/README.md)**

U yerda:
- DNS sozlash
- Serverda birinchi marta deploy qilish
- **Dokploy'da 4 ta domenni `nginx` service'ga ulash** (eng muhim qadam)
- Backup, yangilash, troubleshooting

Har bir qism alohida ham ishga tushadi — `backend/README.md`,
`mobile/README.md`, `admin/README.md`, `curator/README.md`, `landing/README.md`
ga qarang.

> **Eslatma:** bu kompyuterda tizim PostgreSQL'i `5432`-portni egallagani uchun
> loyiha bazasi Docker'da `5544`-portga joylangan (`.env` shunga sozlangan).
> Toza muhitda standart `5432` ishlatilaveradi.

## 🔐 Demo hisoblar
| Panel | Domen | Login | Parol |
|-------|-------|-------|-------|
| Admin | `admin.notiqlik.uz` | `admin@najotnur.uz` | `admin123` |
| Kurator | `curator.notiqlik.uz` | `curator@najotnur.uz` | `curator123` |
| Foydalanuvchi (mobil) | — | telefon OTP | `DEBUG` rejimda kod javobda qaytadi |

## ✅ Tekshirildi
- Backend: 36 API endpoint, migratsiya + seed, auth (OTP→JWT), RBAC (user→admin = 403),
  ovoz tahlili xato so'zlarni aniqladi (`muhim→muxim` h/x tovushi), gating (anon = 401).
- Mobil: `flutter analyze` — **0 xato**.
- Admin, Curator, Landing: `tsc` (strict) + `vite build` — **muvaffaqiyatli**.

## 🗺 Yo'l xaritasi

- [x] Backend poydevori, auth, domen modellar, AI tahlil servisi
- [x] Mobil ilova (onboarding, auth, nutq/ovoz/kuzatuvchanlik, darslar, audiokitob)
- [x] Admin panel (mijozlar, kuratorlar, audiokitob, push)
- [ ] To'lovlar: Uzum, Uzum Nasiya, ATMOS
- [ ] AMOCRM lead integratsiyasi (hook tayyor)
- [ ] PDF sertifikat generatsiyasi (servis tayyor, shablon kerak)
