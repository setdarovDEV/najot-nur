# NotiqAI · Kurator paneli

Najot Nur notiqlik markazining kuratorlar uchun mo'ljallangan boshqaruv paneli.
Bu frontend `curator.notiqlik.uz` domenida ishlaydi (yoki lokal — `localhost:5174`).

## Texnologiyalar
- React 19 + Vite 6 + TypeScript
- Tailwind CSS 4
- TanStack Query 5
- React Router 7

## Imkoniyatlar
- 🏠 Boshqaruv paneli (kutilayotgan vazifalar, o'quvchilar reytingi)
- 📝 Uy vazifalarini tekshirish va baholash
- 🎓 Sertifikat so'rovlarini ko'rib chiqish
- 🎙️ Talaffuz matnlari va ekspert ovozlarini boshqarish
- 🧪 Praktikumlar va testlar (quiz) boshqaruvi
- 📚 Audiokitoblar va video darslar kontenti
- 💬 Foydalanuvchilar bilan yordam chatlari

## Lokal ishga tushirish

```bash
# 1) o'rnatish
npm install

# 2) env sozlash
cp .env.example .env

# 3) dev server
npm run dev   # http://localhost:5174
```

Backend `http://localhost:8000` da ishlab turishi kerak.

## Production build

```bash
npm run build      # dist/ ichida statik fayllar
npm run preview    # lokal preview
```

Production uchun `docker-compose.yml` orqali
`notiq_curator` konteyneriga o'raladi (nginx:alpine SPA).

## Domenlar

| Domen | Tavsif |
|-------|--------|
| `notiqlik.uz` | Landing (marketing) |
| `admin.notiqlik.uz` | Super admin paneli |
| `curator.notiqlik.uz` | **Kurator paneli** (shu frontend) |
| `api.notiqlik.uz` | Backend API |

## Demo hisob

| Email | Parol |
|-------|-------|
| `curator@najotnur.uz` | `curator123` |
