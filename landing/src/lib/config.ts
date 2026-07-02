const env = import.meta.env;

export const BRAND = {
  name: "NotiqAI",
  parent: "Najot Nur",
  tagline: "Nutqingiz va ovozingizni AI orqali 5 daqiqada tekshirib ko‘ring",
  links: {
    // Primary CTA target. If a web-app / deep link is provided at build time,
    // buttons open it; otherwise they scroll to the final CTA section.
    app: (env.VITE_APP_URL as string) || "#boshlash",
    playMarket: (env.VITE_PLAY_MARKET_URL as string) || "#",
    appStore: (env.VITE_APP_STORE_URL as string) || "#",
  },
  contact: {
    email: "info@notiqlik.uz",
    phone: "+998 55 515 65 00",
    phoneRaw: "+998555156500",
    address: "Toshkent sh., Sharq Tongi ko‘chasi, 9A · metro “Novza”",
  },
  social: {
    instagram: "https://www.instagram.com/najotnur_markazi/",
    telegram: "https://t.me/najotnuruz",
    youtube: "https://www.youtube.com/@NajotNur",
  },
} as const;
