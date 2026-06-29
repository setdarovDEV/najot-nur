# NotiqAI — Admin panel (React + Vite)

Kuratorlar va administratorlar uchun boshqaruv paneli.

## Stack
- **React 19 + Vite 6 + TypeScript** (strict)
- **TanStack React Query** (data fetching/caching)
- **React Router 7**
- **Tailwind CSS v4** (`@tailwindcss/vite`, brand tokenlar `@theme` orqali)
- **axios** (token interceptor)

## Sahifalar
- **Boshqaruv paneli** — umumiy ko'rsatkichlar (mijozlar, tahlillar, vazifalar)
- **Mijozlar** — ism, telefon, id, nutq bali; qidiruv + sahifalash; tafsilot sahifasi
- **Uy vazifalari** — kuratorlar uy vazifalarini tekshiradi va ball/izoh qo'yadi
- **Audiokitoblar** — qo'shish, ro'yxat, nashr qilish (sahifa tahriri API tayyor)
- **Bildirishnomalar** — push xabar yuborish + tarix

## Ishga tushirish
```bash
npm install
cp .env.example .env     # VITE_API_URL ni backendga moslang

npm run dev              # http://localhost:5173
npm run build            # tsc (strict) + vite build → dist/
```

## Kirish (demo)
| Rol | Email | Parol |
|-----|-------|-------|
| Admin | `admin@najotnur.uz` | `admin123` |
| Kurator | `curator@najotnur.uz` | `curator123` |

> Kuratorlar `Mijozlar`, `Uy vazifalari`ni ko'radi; `Audiokitoblar` va `Push`
> faqat adminlar uchun (backend RBAC bilan himoyalangan).
