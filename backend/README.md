# NotiqAI — Backend (FastAPI)

AI yordamida nutq/ovoz/kuzatuvchanlik tahlili, kurslar, audiokitoblar, kuratorlar
va admin paneli uchun REST API.

## Stack
- **FastAPI** (async), **SQLAlchemy 2.0** (async) + **asyncpg**, **Alembic**
- **PostgreSQL**, **Redis** (OTP, cache, rate-limit — Redis bo'lmasa graceful)
- **JWT** auth (telefon OTP, Google, Telegram, email/parol)
- **Claude** (Anthropic) — `app/services/ai/*` (deterministik + AI gibrid)
- **structlog** (request-id korrelyatsiya), **reportlab** (PDF sertifikat)

## Struktura
```
app/
├── core/        config, database, redis, security(JWT), logging, middleware, exceptions
├── models/      SQLAlchemy modellari (users, courses, observation, analysis, audiobook, ...)
├── schemas/     Pydantic v2 sxemalar
├── api/v1/      routerlar: auth, users, speech, observation, courses, audiobooks, admin
├── services/    ai/, oauth/, otp, amocrm, storage, certificate, auth_service
└── seeds/       demo ma'lumotlar (admin, kurator, testlar, kurs, audiokitob)
alembic/         migratsiyalar
```

## Ishga tushirish (lokal)
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# DB (Docker bilan eng oson):
docker run -d --name notiq_postgres \
  -e POSTGRES_USER=notiq -e POSTGRES_PASSWORD=notiq_dev_password -e POSTGRES_DB=notiqai \
  -p 5544:5432 postgres:16-alpine

# Root .env da DATABASE_URL portini moslang (masalan 5544), so'ng:
alembic upgrade head
python -m app.seeds.seed          # demo ma'lumotlar
uvicorn app.main:app --reload

# Swagger:  http://localhost:8000/docs
```

## Seed hisoblar
| Rol | Email | Parol |
|-----|-------|-------|
| Admin | `admin@najotnur.uz` | `admin123` |
| Kurator | `curator@najotnur.uz` | `curator123` |

Telefon OTP: `DEBUG=true` bo'lsa `/auth/otp/request` javobida `dev_code` qaytadi.

## Asosiy endpointlar
- `POST /auth/otp/request` · `POST /auth/otp/verify` · `POST /auth/google` · `POST /auth/telegram` · `POST /auth/login` · `POST /auth/refresh`
- `POST /speech/analyze` — nutq tahlili (parazit so'z, pauza, ma'no)
- `POST /speech/voice/analyze` — ovoz/talaffuz (xato so'zlar → `word_errors`, qizil belgilash uchun index)
- `GET  /observation/tests` · `POST /observation/submit` — 10 test + tahlil
- `GET  /courses` · `POST /courses/{id}/enroll` · `POST /courses/lessons/{id}/quiz` (yakunda sertifikat)
- `GET  /audiobooks` · `GET /audiobooks/{id}` · `POST /audiobooks/{id}/progress`
- `GET  /admin/clients` · `POST /admin/homeworks/{id}/grade` · `POST /admin/push` · audiokitob boshqaruvi

> AI: `ANTHROPIC_API_KEY` o'rnatilmasa, tahlillar deterministik rejimda ishlaydi
> (parazit so'z sanash, so'z-darajadagi solishtirish). Key qo'shilsa — Claude
> chuqurroq, mazmunli baho beradi. Model: `AI_MODEL` (default `claude-opus-4-8`).
