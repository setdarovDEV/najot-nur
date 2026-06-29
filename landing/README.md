# NotiqAI · Landing (marketing sahifa)

Najot Nur notiqlik markazining ommaviy marketing sahifasi.
`notiqlik.uz` domenida ishlaydi (yoki lokal — `localhost:5175`).

## Texnologiyalar
- React 19 + Vite 6 + TypeScript
- Tailwind CSS 4 (brand tokens)
- Lucide React (ikonlar)

## Bo'limlar
- 🏠 Hero (asosiy taklif)
- ✨ Imkoniyatlar (6 ta modul)
- 🔁 Qanday ishlaydi (3 qadam)
- 📊 Statistika
- 💰 Narxlar (Bepul, Pro, Jamoa)
- 💬 Foydalanuvchilar fikri
- ❓ FAQ (accordion)
- 📥 CTA (mobil ilovaga yo'naltirish)
- ✉️ Bog'lanish formasi
- 🔗 Footer

## Lokal ishga tushirish

```bash
npm install
npm run dev      # http://localhost:5175
```

## Production build

```bash
npm run build    # dist/ ichida statik fayllar
```

Production uchun `docker-compose.deploy.yml` orqali
`notiq_landing` konteyneriga o'raladi (nginx:alpine SPA).

## Domen

| Domen | Tavsif |
|-------|--------|
| `notiqlik.uz` | **Landing (marketing sahifa)** — shu frontend |
| `www.notiqlik.uz` | Landing (www) |
| `admin.notiqlik.uz` | Admin paneli |
| `curator.notiqlik.uz` | Kurator paneli |
| `api.notiqlik.uz` | Backend API |
