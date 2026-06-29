# NotiqAI — server deployment

Production stack lives on **`45.138.159.219`** at **`/opt/notiqai/`**.

## Public endpoints

| Subdomain | Service | Notes |
|---|---|---|
| `notiqlik.uz` / `www.notiqlik.uz` | Landing (static) | Marketing page, links to admin/curator/API |
| `admin.notiqlik.uz` | Admin panel | React + Vite SPA, served by `notiq_admin` container |
| `curator.notiqlik.uz` | Curator panel | Same SPA, curator role login |
| `api.notiqlik.uz` | FastAPI backend | `/api/v1/*`, `/docs`, `/openapi.json`, `/health`, `/media/*` |

All routed by `notiq_nginx` (nginx 1.27) with HTTP→HTTPS redirect
(once TLS is enabled via `setup-https.sh`).

## Container layout

```
notiq_nginx      nginx:1.27-alpine  ── public entry point
notiq_admin      notiqai-admin      ── React SPA (vite build, served by internal nginx)
notiq_backend    notiqai-backend    ── FastAPI + gunicorn (2 uvicorn workers)
notiq_postgres   postgres:16-alpine ── primary DB
notiq_redis      redis:7-alpine     ── cache + rate-limit store
```

## Daily operations (SSH into the server first)

```bash
ssh notiqai                                 # passwordless via ed25519
cd /opt/notiqai

deploy/logs.sh                              # tail all containers
deploy/logs.sh backend                      # tail one service
deploy/update.sh                            # rebuild images + restart
deploy/backup.sh                            # pg_dump + media tar to /var/backups/notiqai
deploy/setup-https.sh                       # one-shot Let's Encrypt enable (needs DNS first)
```

Inside the container, common commands:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
docker compose ... logs -f backend
docker exec notiq_backend python -m app.seeds.seed   # idempotent
docker exec -it notiq_postgres psql -U notiq -d notiqai
```

## How to enable HTTPS

1. Point DNS A-records for these 5 hosts to `45.138.159.219`:
   `notiqlik.uz`, `www.notiqlik.uz`, `admin.notiqlik.uz`,
   `curator.notiqlik.uz`, `api.notiqlik.uz`.
2. Wait for propagation (`dig +short notiqlik.uz @8.8.8.8` should return `45.138.159.219`).
3. Run:
   ```bash
   ssh notiqai
   cd /opt/notiqai && deploy/setup-https.sh
   ```
4. The script installs Let's Encrypt certs at
   `/etc/letsencrypt/live/notiqai/`, switches nginx to SSL, and
   registers a daily 03:00 cron for `certbot renew`.

## Security baseline already applied

- `POSTGRES_PASSWORD` and `JWT_SECRET_KEY` are unique 256-bit random
  hex strings generated on the server (`/opt/notiqai/.env`, mode 600).
- UFW: only 22, 80, 443 open. Everything else dropped.
- `DOCKER-USER` chain drops external traffic to backend (8000),
  admin dev (5173), postgres (5432), redis (6382).
- Backend runs as non-root user `app`, image has `tini` PID 1.
- Rate-limit zones:
  - 30 r/s for the API.
  - 5 r/min for `/api/v1/auth/*` (OTP brute-force guard).
- HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy on all responses (after HTTPS is on).
- Daily `certbot renew` cron after HTTPS is enabled.

## Backup policy

`deploy/backup.sh` (run via `0 3 * * *` after wiring up cron) does:
- `pg_dump` of the live database → `/var/backups/notiqai/db-YYYYMMDDTHHMMSS.sql.gz`
- copy of `.env` (chmod 600)
- `tar` of the `media` volume
- 14-day retention

## Updating the application

1. Edit code locally in `/home/abbbose/projects/najot-nur`.
2. `rsync` or `scp` the changed files to `/opt/notiqai/` on the server.
3. `ssh notiqai "cd /opt/notiqai && deploy/update.sh"` rebuilds images
   and restarts containers in-place (DB volumes are preserved).

For frontend-only changes, only the `admin` image needs rebuilding —
faster:
```bash
ssh notiqai "cd /opt/notiqai && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml build admin && \
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d admin"
```
