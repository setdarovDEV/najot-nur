export const BRAND = {
  name: "NotiqAI",
  parent: "Najot Nur",
  parentUrl: "https://najotnur.uz",
  tagline: "So'zlash san'atini AI bilan o'rganing",
  description:
    "NotiqAI — nutqingiz, ovozingiz va kuzatuvchanligingizni sun'iy intellekt yordamida tahlil qiladigan platforma. Har bir mashg'ulotda aniq tavsiyalar.",
  colors: {
    wine: "#8A1538",
    wineDark: "#5E0E25",
    wineDeep: "#3F0918",
    orange: "#FF5C39",
    skyblue: "#5BC2E7",
    ink: "#14181F",
    paper: "#FAF7F4",
    muted: "#6B7280",
  },
  links: {
    admin: "https://admin.notiqlik.uz",
    curator: "https://curator.notiqlik.uz",
    api: "https://api.notiqlik.uz/docs",
    playMarket: "#",
    appStore: "#",
  },
  contact: {
    email: "info@notiqlik.uz",
    phone: "+998 71 200 00 00",
    address: "Toshkent sh., Amir Temur ko'chasi, 1-uy",
  },
  social: {
    instagram: "https://instagram.com/notiqai",
    telegram: "https://t.me/notiqai",
    facebook: "https://facebook.com/notiqai",
    youtube: "https://youtube.com/@notiqai",
  },
} as const;

export type SiteConfig = typeof BRAND;
