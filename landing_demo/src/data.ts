import { QuizQuestion, TestResult } from "./types";

export const QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: 1,
    question: "Suhbatdoshingiz sizni tinglayotganda qo'llarini ko'kragiga chatishtirdi (kross qildi) va bir oz orqaga chekindi. Bu nimani anglatadi?",
    options: [
      { key: "A", text: "U sizga to'liq ishonmoqda va dam olmoqda", isCorrect: false },
      { key: "B", text: "U himoyalanish, skeptiklik yoki qarshilik ko'rsatish holatida", isCorrect: true },
      { key: "C", text: "U shunchaki jismonan charchagan va qulay joylashmoqchi", isCorrect: false }
    ],
    explanation: "Qo'llarni chatishtirish va orqaga chekinish ko'pincha noverbal muloqotda mudofaa (himoya) to'sig'ini yaratish va suhbatdoshdan masofa saqlash istagini anglatadi."
  },
  {
    id: 2,
    question: "Suhbat davomida inson tez-tez bo'ynini silaydi yoki teginadi. Bu qanday noverbal signal?",
    options: [
      { key: "A", text: "O'ziga bo'lgan haddan tashqari ishonch va ustunlik signali", isCorrect: false },
      { key: "B", text: "Charchoq yoki shunchaki uyqu kelayotganligi belgisi", isCorrect: false },
      { key: "C", text: "Bezovtalik, stress, xavotir yoki noqulaylikni yumshatishga urinish", isCorrect: true }
    ],
    explanation: "Bo'yin qismini silash yoki teginish (ayniqsa bo'yin orqa qismini yoki bo'yinturuq sohasini) tinchlantiruvchi (adaptiv) harakat hisoblanib, inson ichki stress yoki bezovtalikni jilovlashga urinayotganini bildiradi."
  },
  {
    id: 3,
    question: "Inson faqat og'zi bilan jilmaymoqda, lekin uning ko'zlari atrofida mayda ajinlar ('g'oz panjasi') paydo bo'lmadi. Bu tabassum haqida nima deyish mumkin?",
    options: [
      { key: "A", text: "Bu juda samimiy va chin dildan chiqayotgan tabassum", isCorrect: false },
      { key: "B", text: "Bu sun'iy, shunchaki xushmuomalalik uchun qilingan soxta tabassum", isCorrect: true },
      { key: "C", text: "U sizning gaplaringizdan jahli chiqayotganligini bildiradi", isCorrect: false }
    ],
    explanation: "Haqiqiy samimiy tabassum (Dyuşen tabassumi) nafaqat og'iz cheti mushaklarini, balki ko'z atrofidagi 'orbicularis oculi' mushaklarini ham faollashtiradi va ko'z chetlarida ajinchalar hosil qiladi."
  },
  {
    id: 4,
    question: "Suhbatdoshingizning ko'z qorachiqlari siz bilan gaplashayotganda bir oz kengaydi (agar atrofda yorug'lik o'zgarmagan bo'lsa). Bu nima haqida xabar beradi?",
    options: [
      { key: "A", text: "U sizdan juda zerikmoqda va suhbatni tugatmoqchi", isCorrect: false },
      { key: "B", text: "Suhbat mavzusi yoki shaxsan siz unda qiziqish va yoqimli hislar uyg'otyapsiz", isCorrect: true },
      { key: "C", text: "U sizga nisbatan qo'rquv va chuqur shubha his qilmoqda", isCorrect: false }
    ],
    explanation: "Noverbal psixologiyada ko'z qorachig'ining kengayishi (yorug'lik barqaror bo'lganda) asab tizimining yoqimli stimulyatsiyasini, ya'ni suhbatdoshga yoki suhbat mavzusiga bo'lgan kuchli qiziqish va simpatiyani anglatadi."
  }
];

export const MOCK_SPEECH_RESULT: TestResult = {
  overallScore: 84,
  metrics: [
    { label: "Ovoz ishonchliligi (Confidence)", score: 88, description: "Ovoz ohangi barqaror va ishonchli eshitiladi, titrashlar deyarli yo'q." },
    { label: "Pauzalar balansi (Pauses)", score: 82, description: "Fikrlar orasidagi pauzalar o'rtacha 1.5-2 soniya bo'lib, ideal balansda." },
    { label: "Parazit so'zlar miqdori (Filler Words)", score: 75, description: "Nutq davomida bir nechta keraksiz to'ldiruvchi so'zlar aniqlandi." },
    { label: "Fikr izchilligi (Coherence)", score: 91, description: "Gaplar mantiqiy bog'langan va tushunarli tartibda bayon qilindi." }
  ],
  fillerWords: [
    { word: "haligi", count: 2 },
    { word: "xo'sh", count: 3 },
    { word: "ya'ni", count: 1 }
  ],
  feedback: "Sizning nutqingiz juda yaxshi darajada shakllangan! Ovoz ohangingiz ishonchli va tinglovchini jalb qila oladi. Faqat gap boshlashdan oldin 'xo'sh' yoki 'haligi' kabi parazit so'zlarni kamaytirish orqali nutqingizni yanada mukammal va ta'sirli qilishingiz mumkin.",
  accentTitle: "A'lo darajadagi ma'ruzachi"
};

export const MOCK_VOICE_RESULT: TestResult = {
  overallScore: 78,
  metrics: [
    { label: "Talaffuz aniqligi (Pronunciation)", score: 86, description: "Sinflar va murakkab so'z birikmalari yetarlicha aniq aytildi." },
    { label: "Nutq tezligi (Pacing)", score: 80, description: "Tezlik minutiga ~125 so'zni tashkil etdi (Tavsiya etilgan: 120-140)." },
    { label: "Intonatsiya va ohang (Emotion)", score: 74, description: "Nutq ohangi bir oz monoton eshitildi. Matndagi nuqta va so'roqlarga e'tibor bering." },
    { label: "Diksiyaning ravonligi (Clarity)", score: 72, description: "Ayrim harflarning talaffuzi pastroq ovoz tufayli bir oz loyqa chiqdi." }
  ],
  fillerWords: [],
  feedback: "Siz berilgan matnni muvaffaqiyatli o'qidingiz! Talaffuz aniqligi yuqori, ammo nutqingizga ko'proq hissiyot (intonatsiya) qo'shish tavsiya etiladi. Matndagi tinish belgilariga qarab ovoz balandligini o'zgartiring va mikrofonga yaqinroq, ishonchliroq ovozda gapiring.",
  accentTitle: "Yaxshi diktorlik salohiyati"
};
