# NotiqAI — server deployment (Dokploy)

Production stack lives on **`45.138.159.219`** at **`/opt/notiqai/`**.
Dokploy is the deployment platform (Traefik handles HTTPS in front
of the stack).

## Build / deploy pipeline

```
git push origin main
      ↓
GitHub Actions (.github/workflows/build.yml)
  → builds 4 images on GitHub's infrastructure
  → pushes to GitHub Container Registry (ghcr.io/setdarovdev/najot-nur-*)
      ↓
Dokploy pulls :latest images and starts containers (no build on server)
```

**Why this is fast**: Dokploy's server is small, building Docker images
on it took 5-10 minutes per deploy. With GH Actions, builds are parallel
on GitHub's runners and finish in 2-4 minutes total.

## Public endpoints

| Subdomain | Service | Notes |
|---|---|---|
| `notiqlik.uz` / `www.notiqlik.uz` | Landing (static) | Marketing page |
| `admin.notiqlik.uz` | Admin panel | React + Vite SPA |
| `curator.notiqlik.uz` | Curator panel | React + Vite SPA |
| `api.notiqlik.uz` | FastAPI backend | `/api/v1/*`, `/docs`, `/openapi.json`, `/health`, `/media/*` |

Dokploy'ning Traefik'i 4 ta domenni **bitta** `nginx` service'ga
(port 80) yo'naltiradi. Nginx `Host` header orqali ichki
service'larga ajratadi (single-entry-point arxitekturasi).

## Container layout

```
notiq_nginx      nginx:1.27-alpine  ── public entry point (HTTP)
notiq_admin      ghcr.io/...admin   ── React SPA (vite build, internal nginx)
notiq_curator    ghcr.io/...curator ── React SPA (vite build, internal nginx)
notiq_landing    ghcr.io/...landing ── React SPA (vite build, internal nginx)
notiq_backend    ghcr.io/...backend ── FastAPI + gunicorn
notiq_postgres   postgres:16-alpine ── primary DB
notiq_redis      redis:7-alpine     ── cache + rate-limit
```

## First-time setup on a fresh server

1. **DNS**: 4 ta A-record `45.138.159.219` ga qarating:
   `notiqlik.uz`, `www.notiqlik.uz`, `admin.notiqlik.uz`,
   `curator.notiqlik.uz`, `api.notiqlik.uz`.
2. **Kodni ko'chirish**:
   ```bash
   rsync -avz --delete /home/abbbose/projects/najot-nur/ \
     notiqai@45.138.159.219:/opt/notiqai/
   ```
3. **`.env` tayyorlash** (serverda):
   ```bash
   cd /opt/notiqai
   cp .env.production.example .env
   nano .env          # CHANGE_ME larni haqiqiy qiymatga almashtiring
   chmod 600 .env
   ```
4. **Birinchi deploy** (serverda):
   ```bash
   bash deploy/deploy.sh
   ```
5. **Dokploy'ga 4 ta domen ulash** — eng muhim qadam:
   - Login: `http://45.138.159.219:3000`
   - `Projects` → `notiqai` → `Domains` tab
   - Quyidagi 4 ta domenni qo'shing, **har biri `nginx` service'ga
     va `port 80`** ga ulangan bo'lsin:

     | Host | Service | Port |
     |---|---|---|
     | `notiqlik.uz` | nginx | 80 |
     | `www.notiqlik.uz` | nginx | 80 |
     | `admin.notiqlik.uz` | nginx | 80 |
     | `curator.notiqlik.uz` | nginx | 80 |
     | `api.notiqlik.uz` | nginx | 80 |

   - HTTPS toggle'ni yoqing (Let's Encrypt avtomatik beradi).

## Deploy keyingi kod o'zgarishlarida

Oddiy ish jarayoni endi shunday:

```bash
# 1) Lokal'da kodni o'zgartiring
git add -A
git commit -m "..."
git push origin main
# 2) GitHub Actions 2-4 daqiqada image'larni quradi
# 3) Dokploy avtomatik (yoki qo'lda) yangilangan image'larni tortadi
# 4) Eski konteynerlar yangilanadi, downtime ~10 soniya
```

Dokploy'ning image-watch funksiyasi yoqilgan bo'lsa, **hech narsa
qilish shart emas** — push qilish bilanoq yangilanadi. Aks holda
Dokploy UI → notiqai → **Deploy** tugmasini bosing.

## Daily operations

```bash
ssh notiqai
cd /opt/notiqai

deploy/logs.sh                 # tail all containers
deploy/logs.sh backend         # tail one service
deploy/backup.sh               # pg_dump + media tar
```

Inside the stack:
```bash
docker compose -f docker-compose.yml ps
docker compose -f docker-compose.yml logs -f backend
docker exec notiq_backend python -m app.seeds.seed   # idempotent
docker exec -it notiq_postgres psql -U notiq -d notiqai
```

## Security baseline already applied

- `POSTGRES_PASSWORD` va `JWT_SECRET_KEY` serverda 256-bit hex bilan
  generatsiya qilingan (`/opt/notiqai/.env`, mode 600).
- UFW: faqat 22, 80, 443 ochiq.
- `DOCKER-USER` chain tashqi trafikni backend (8000), postgres (5432),
  redis (6379) ga tushiradi.
- Backend non-root `app` user bilan ishlaydi, `tini` PID 1.
- Rate-limit zones:
  - 30 r/s umumiy API
  - 5 r/min `/api/v1/auth/*` (OTP brute-force guard)
- HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy
  (Dokploy Traefik tomonidan qo'shiladi).

## Backup policy

`deploy/backup.sh` (`0 3 * * *` cron orqali):
- `pg_dump` → `/var/backups/notiqai/db-YYYYMMDDTHHMMSS.sql.gz`
- `.env` nusxasi (chmod 600)
- `media` volume tar
- 14 kun retention
