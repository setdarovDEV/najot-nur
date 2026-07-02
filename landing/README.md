# NotiqAI Landing

Konversion landing sahifa — `docs/landing_tz.txt` TZ va `docs/NN_aydentika.pdf`
brand aydentikasi asosida qurilgan. Vite + React 19 + TypeScript + Tailwind CSS v4.

## Ishga tushirish

```bash
npm install
npm run dev        # http://localhost:5175
npm run build      # tsc + vite build → dist/
```

## Muhit o‘zgaruvchilari (build vaqtida)

| O‘zgaruvchi            | Vazifasi                                              | Default      |
| ---------------------- | ----------------------------------------------------- | ------------ |
| `VITE_APP_URL`         | Barcha CTA tugmalar ochadigan manzil (web-app / link) | `#boshlash`  |
| `VITE_PLAY_MARKET_URL` | Google Play havolasi                                  | `#`          |
| `VITE_APP_STORE_URL`   | App Store havolasi                                    | `#`          |

`VITE_APP_URL` berilmasa, CTA tugmalar sahifa oxiridagi Final CTA blokiga olib boradi.

## Tracking

CTA bosishlar `window.dataLayer` ga push qilinadi (GTM/Pixel uchun tayyor).
Event nomlari TZ 12-bo‘lim bo‘yicha qat'iy:

- `speech_test_click`
- `voice_test_click`
- `observation_test_click`
- `main_cta_click`

## Deploy

`Dockerfile.prod` — statik build + nginx (port 80, healthcheck bilan),
`docker-compose.yml` dagi `landing` servisi va GH Actions build pipeline'iga mos.
