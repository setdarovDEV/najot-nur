export const BRAND = {
  name: "NotiqAI",
  parent: "Najot Nur",
  parentUrl: "https://najotnur.uz",
  parentFounded: 2018,
  parentGraduates: "5,300+",
  parentFollowers: "200K+",
  parentCities: 12,
  parentCourses: 24,
  tagline: "So'zlash san'atini AI bilan o'rganing",
  description:
    "NotiqAI — nutqingiz, ovozingiz va kuzatuvchanligingizni sun'iy intellekt yordamida tahlil qiladigan platforma. Har bir mashg'ulotda aniq tavsiyalar.",
  about: {
    intro:
      "Najot Nur — O'zbekistondagi eng yirik notiqlik va shaxsiy rivojlanish markazi. 2018-yilda tashkil etilgan markaz bugungi kunda 5,300 dan ortiq bitiruvchini tarbiyalab, 200 mingdan ziyod ijtimoiy tarmoq obunachilariga ega.",
    mission:
      "Maqsadimiz — har bir odam o'z fikrini ishonchli, ta'sirli va ravon yetkaza oladigan jamiyat qurish. Biz nazariyani amaliyot, amaliyotni natija, natijani esa yangi imkoniyatlarga aylantiramiz.",
    pillars: [
      {
        title: "Amaliy mashg'ulotlar",
        text: "Har bir darsda kamera oldida chiqish, sahna tajribasi va real auditoriya bilan ishlash.",
      },
      {
        title: "Tajribali kuratorlar",
        text: "Jurnalist, teleboshlovchi va soha ekspertlari — 18 nafar doimiy kurator siz bilan ishlaydi.",
      },
      {
        title: "AI yordamida tahlil",
        text: "Nutq tezligi, parazit so'zlar, emotsiya va tana tili — barchasi NotiqAI tomonidan avtomatik tahlil qilinadi.",
      },
    ],
    milestones: [
      { year: "2018", text: "Najot Nur notiqlik markazi ta'sis etildi" },
      { year: "2020", text: "Onlayn intensiv-kurslar va AUDIONOMA audiokitoblar loyihasi boshladi" },
      { year: "2022", text: "YouTube va ijtimoiy tarmoqlarda 100K+ auditoriyaga yetildi" },
      { year: "2024", text: "NotiqAI platformasi — AI yordamida shaxsiy tahlil xizmati ishga tushdi" },
      { year: "2026", text: "12+ shaharda faoliyat, 5,300+ bitiruvchi va mobil ilovalar" },
    ],
  },
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
    phone: "+998 55 515 65 00",
    phoneRaw: "+998555156500",
    address: "Toshkent sh., Sharq Tongi ko'chasi, 9A · metro \"Novza\"",
    workHours: "Dush–Shan: 09:00 — 21:00",
  },
  social: {
    instagram: "https://www.instagram.com/najotnur_markazi/",
    instagramOfficial: "https://www.instagram.com/najotnur_official/",
    telegram: "https://t.me/najotnuruz",
    telegramAdmin: "https://t.me/notiqlik_admin",
    facebook: "https://www.facebook.com/100085398356579/",
    youtube: "https://www.youtube.com/@NajotNur",
    youtubeMarkaz: "https://www.youtube.com/@NotiqlikMarkazi",
  },
} as const;

export type SiteConfig = typeof BRAND;
