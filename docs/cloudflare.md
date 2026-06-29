# Cloudflare Tunnel — backend'ni tashqariga ochish

Lokal backend (`localhost:8001`) ni telefondan chaqirish uchun
Cloudflare quick tunnel ishlatamiz.

## Tez boshlash

```bash
./scripts/start_cloudflared.sh
```

Skript:

1. Eski cloudflared tunnelni o'chiradi
2. Yangi quick tunnel ochadi (`*.trycloudflare.com`)
3. Public https URL'ni oladi
4. Tayyor `flutter run` buyrug'ini chiqaradi

## Mobile'ni ishga tushirish

Skript chiqargan URL bilan:

```bash
cd mobile
flutter run --dart-define=API_URL=https://<sizning-subdomain>.trycloudflare.com/api/v1
```

> **Muhim:** `--dart-define=API_URL=...` ishlatgan holda `AppConstants.apiUrl`
> ning default qiymati e'tibor berilmaydi.

## Eslatmalar

- **Quick tunnel** — login talab qilmaydi, lekin URL har safar
  tunnel qayta ochilganda almashinadi.
- **Barqaror URL** — `cloudflared tunnel login` + named tunnel yarating
  (batafsil: <https://developers.cloudflare.com/cloudflare-one/connections/connect-apps>).
- **Cloudflared panel** — quick tunnel'da yo'q (faqat named tunnel uchun).
- **Log** — `tail -f /tmp/cloudflared.log`.
- **Backend port** — standart `8001`. Boshqa port uchun:
  `BACKEND_PORT=8081 ./scripts/start_cloudflared.sh`.

## Muammolarni hal qilish

| Xato | Sabab | Yechim |
|------|-------|--------|
| `cloudflared: command not found` | O'rnatilmagan | <https://pkg.cloudflare.com/> dan yuklab oling |
| URL chiqmayapti | Internet yo'q yoki port band | `tail -f /tmp/cloudflared.log` |
| `tunnel offline` | Backend ishlamayapti | `curl http://localhost:8001/docs` |
