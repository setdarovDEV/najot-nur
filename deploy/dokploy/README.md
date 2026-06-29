# NotiqAI — Dokploy deployment

Bu papka Dokploy (yoki boshqa self-hosted Docker Compose PaaS) orqali
**bitta komanda** bilan NotiqAI'ni ishga tushirish uchun tayyorlangan.

## Nima ishlaydi

Bir `docker compose -f docker-compose.deploy.yml up -d` ishga tushiradi:

| Servis | Image | Port | Hajmi |
|--------|-------|------|-------|
| `notiq_postgres` | `postgres:16-alpine` | 5432 (internal) | 384 MB |
| `notiq_redis`    | `redis:7-alpine`    | 6379 (internal) | 192 MB |
| `notiq_backend`  | `notiqai-backend`   | 8000 (internal) | 512 MB |
| `notiq_admin`    | `notiqai-admin`     | 80   (internal) | 64 MB |
| `notiq_nginx`    | `notiqai-nginx`     | 80, 443 (host)   | 64 MB |
| `notiq_certbot`  | `certbot/certbot`   | —               | profile: `ssl` |

Barcha servislar `notiq` bridge network orqali gaplashadi.
Faqat `nginx` tashqi (host) portlarda eshitadi.

## Tezkor start (Dokploy)

### Variant A — Dokploy'ning o‘z Traefik'i TLS ni boshqaradi (tavsiya)

1. **Dokploy** → **Create Service** → **Docker Compose**.
2. **Source**: Git repo URL (yoki `Upload` orqali papka yuklang).
3. **Compose file**: `docker-compose.deploy.yml`.
4. **Environment** bo'limiga `.env.production.example` dagini
   ko'chirib, `CHANGE_ME_*` o'rniga haqiqiy qiymatlarni qo'ying.
   Kamida shu o'zgaruvchilar **required**:
   ```
   POSTGRES_PASSWORD=...
   JWT_SECRET_KEY=...
   VITE_API_URL=/api/v1
   ```
5. **Domains**: `notiqlik.uz`, `admin.notiqlik.uz`,
   `curator.notiqlik.uz`, `api.notiqlik.uz` — barchasini
   shu compose service'ga yo'naltiring (Traefik 80-portga
   proxy qiladi). Traefik o'zi Let's Encrypt oladi.
6. **Deploy**.

> Bu rejimda nginx **HTTP** rejimda ishlaydi, SSL ni Dokploy
> Traefik tashqarida terminate qiladi. Bu eng sodda yo'l.

### Variant B — Nginx o‘zi Let's Encrypt oladi (self-managed SSL)

1. Yuqoridagi 1-4 qadamlar.
2. `ENABLE_HTTPS=true` qo'ying.
3. DNS A-recordlarni server IP'ga yo'naltirib, **30 daqiqa kuting**.
4. Birinchi marta SSL sertifikatini oling:
   ```bash
   docker compose -f docker-compose.deploy.yml --profile ssl run --rm \
     certbot certonly --webroot -w /var/www/certbot \
       -d notiqlik.uz -d www.notiqlik.uz \
       -d admin.notiqlik.uz -d curator.notiqlik.uz -d api.notiqlik.uz \
       -d dokploy.notiqlik.uz \
       --cert-name notiqai --non-interactive --agree-tos -m admin@notiqlik.uz
   ```
   yoki qisqacha:
   ```bash
   bash deploy/dokploy/init-letsencrypt.sh
   ```
5. Certbot konteynerni doimiy ravishda ishga tushiring (auto-renewal):
   ```bash
   docker compose -f docker-compose.deploy.yml --profile ssl up -d certbot
   ```
6. Nginx'ni qayta ishga tushiring — endi u HTTPS bloklarini
   avtomatik faollashtiradi:
   ```bash
   docker compose -f docker-compose.deploy.yml restart nginx
   ```

## Tekshirish

```bash
# Barcha konteynerlar "healthy" yoki "Up" bo'lishi kerak
docker compose -f docker-compose.deploy.yml ps

# Loglarni real-time ko'rish
docker compose -f docker-compose.deploy.yml logs -f --tail=100

# Faqat backend loglari
docker compose -f docker-compose.deploy.yml logs -f backend

# Healthcheck
curl http://localhost/health
# → {"status":"ok","app":"NotiqAI","env":"production"}
```

## Birinchi deploy'da demo ma'lumotlarni yuklash

Birinchi marta `RUN_SEEDS=true` qo'ying, keyin `false` qilib qo'ying.
Seedlar idempotent (qayta ishga tushirish zararli emas), lekin
har startda yozib o'tirmaslik yaxshiroq.

```env
RUN_SEEDS=true
```

Birinchi deploy'dan keyin:
- `admin@najotnur.uz` / `admin123`
- `curator@najotnur.uz` / `curator123`

## Yangilash (keyingi release'lar)

```bash
# 1) Yangi kodni serverga torting
cd /opt/notiqai
git pull        # yoki rsync

# 2) Image'larni rebuild qilib, konteynerlarni yangilang
docker compose -f docker-compose.deploy.yml build --pull
docker compose -f docker-compose.deploy.yml up -d

# 3) Eski image'larni tozalash
docker image prune -f
```

Frontend faqat o'zgargan bo'lsa (tezkor):
```bash
docker compose -f docker-compose.deploy.yml build admin
docker compose -f docker-compose.deploy.yml up -d admin
```

## Backup

```bash
# PostgreSQL dump
docker exec notiq_postgres pg_dump -U notiq -d notiqai \
  | gzip > backup-$(date +%Y%m%d).sql.gz

# Media volume
docker run --rm \
  -v notiqai_media:/data:ro \
  -v $(pwd):/backup \
  alpine:3.20 \
  tar -czf /backup/media-$(date +%Y%m%d).tar.gz -C /data .
```

## Xavfsizlik eslatmalari

- `POSTGRES_PASSWORD` va `JWT_SECRET_KEY` ni hech qachon git'ga commit qilmang.
- `RUN_SEEDS=false` qiling — production'da default holatda o'chirilgan.
- Faqat **80** va **443** portlarni ochiq qoldiring (UFW / security group).
- Backend va admin portlari (`8000`, `5173`, `5432`, `6379`)
  **faqat ichki** — hostda expose qilinmagan.
- Let's Encrypt avtomatik yangilanishi uchun certbot konteyner doimiy ishlashi kerak
  (faqat `--profile ssl` bilan).

## Tuzilma

```
najot-nur/
├── docker-compose.deploy.yml   ← Shu faylni Dokploy'ga bering
├── .env.production.example     ← Environment variable shabloni
├── backend/
│   ├── Dockerfile.prod         ← Backend image
│   └── app/, alembic/, requirements.txt, …
├── admin/
│   ├── Dockerfile.prod         ← Admin SPA image (VITE_API_URL)
│   ├── src/, package.json, …
├── deploy/
│   ├── nginx/
│   │   ├── nginx.conf          ← Upstreams, gzip, rate-limit
│   │   ├── conf.d/             ← HTTP server blocks (default)
│   │   ├── conf.d-ssl/         ← HTTPS server blocks (auto-activated)
│   │   ├── www/                ← Landing page (static HTML)
│   │   └── certbot/www/        ← ACME challenge root
│   └── dokploy/                ← Bu papka
│       ├── Dockerfile.nginx    ← Custom nginx image (smart entrypoint)
│       ├── nginx-entrypoint.sh ← HTTP/HTTPS autodetect
│       ├── init-letsencrypt.sh ← Bir martalik SSL olish
│       └── README.md           ← Siz shu fayldasiz
└── mobile/                     ← Flutter ilova (deploy qilinmaydi,
                                  alohida build: APK/IPA)
```
