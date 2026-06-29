"""Generate observation tests with AI based on difficulty level."""
from __future__ import annotations

import uuid
from typing import Literal

from app.services.ai.client import structured_completion

_SYSTEM = (
    "Siz NotiqAI — kuzatuvchanlik va psixologiya bo'yicha mutaxassis murabbiysiz. "
    "Vazifangiz: foydalanuvchi uchun kuzatuvchanlik testi yaratish. "
    "Barcha savol va javoblar O'ZBEK tilida bo'lishi kerak. "
    "Testlar uchta soha bo'yicha bo'lsin: psixologiya (psychology), "
    "tana tili (body_language), kuzatuvchanlik (observation). "
    "Har bir savolda 4 ta javob varianti va 1 ta to'g'ri javob indeksi bo'lsin."
)

_DIFFICULTY_HINTS: dict[str, str] = {
    "easy": (
        "Oson daraja: oddiy, hayotiy holatlarga asoslangan savollar. "
        "Javob variantlari aniq farqlanadi, to'g'ri javob nisbatan ravshan. "
        "Maktab o'quvchisi ham tushuna oladigan tilda yozing."
    ),
    "medium": (
        "O'rtacha daraja: biroz o'ylashni talab etadigan savollar. "
        "Javob variantlari ba'zan o'xshash, diqqat kerak. "
        "Ikki javob varianti maqbul ko'rinsa-da, faqat bittasi to'g'ri."
    ),
    "hard": (
        "Qiyin daraja: murakkab psixologik va kuzatuvchanlik holatlari. "
        "Javob variantlari juda o'xshash, nozik farqlar bor. "
        "Chuqur tahlil va tajriba talab etiladi. "
        "Ekspert darajasidagi kuzatuvchanlik sinovi."
    ),
}

_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "tests": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "prompt": {"type": "string"},
                    "category": {
                        "type": "string",
                        "enum": ["psychology", "body_language", "observation"],
                    },
                    "options": {
                        "type": "array",
                        "items": {"type": "string"},
                        "minItems": 4,
                        "maxItems": 4,
                    },
                    "correct_option": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 3,
                    },
                },
                "required": ["title", "prompt", "category", "options", "correct_option"],
            },
            "minItems": 10,
            "maxItems": 10,
        }
    },
    "required": ["tests"],
}

_FALLBACK: dict[str, list[dict]] = {
    "easy": [
        {"title": "Tabassum", "prompt": "Do'stingiz siz bilan uchrashganda keng jilmaydi. Bu nimani bildiradi?", "category": "psychology", "options": ["Sizni yoqtiradi", "Zerikyapti", "G'amgin", "Rozi emas"], "correct_option": 0},
        {"title": "Ko'z teginishi", "prompt": "Suhbatda odam ko'zingizga qaramaydi. Odatda bu nima degani?", "category": "body_language", "options": ["Ishonchli", "Yolg'on yoki noqulaylik", "Xursand", "Diqqatli"], "correct_option": 1},
        {"title": "Rangi", "prompt": "Harakatlanuvchi ob'ektlarda qaysi rang ko'proq e'tiborni tortadi?", "category": "observation", "options": ["Ko'k", "Yashil", "Qizil", "Sariq"], "correct_option": 2},
        {"title": "Ijobiy munosabat", "prompt": "Inson siz bilan gaplashganda oldinga egiladi. Bu nimani anglatadi?", "category": "body_language", "options": ["Zerikish", "Qiziqish va diqqat", "G'azab", "Uyqu"], "correct_option": 1},
        {"title": "Hissiy holatni aniqlash", "prompt": "Kollegangiz bugun jimgina ishlayapti. Siz nima deb o'ylaysiz?", "category": "psychology", "options": ["Kasal", "G'amgin yoki muammosi bor", "Uxlagan", "Kimnidir kutmoqda"], "correct_option": 1},
        {"title": "Qo'l holati", "prompt": "Odam qo'llarini ko'krak oldida qoplaydi. Bu odatda nimani bildiradi?", "category": "body_language", "options": ["Ochiqlik", "Himoyalanish", "Xursandlik", "Qiziqish"], "correct_option": 1},
        {"title": "Xona o'zgarishi", "prompt": "Xonaga kirganda birinchi navbatda nimaga e'tibor berasiz?", "category": "observation", "options": ["Ranglar", "Odamlar soni", "Chiqish yo'li", "Yangi narsalar"], "correct_option": 3},
        {"title": "Stress belgilari", "prompt": "Notanish odam ko'p qayta-qayta bir narsani tekshiradi. Bu nimadan darak beradi?", "category": "psychology", "options": ["Ehtiyotkorlik", "Tashvish va stress", "Qiziqish", "Professionallik"], "correct_option": 1},
        {"title": "Ovoz ohagi", "prompt": "Odam past va sekin gapiради. Bu odatda qanday holatni bildiradi?", "category": "body_language", "options": ["G'azab", "Xursandlik", "Xotirjamlik yoki g'am", "Qo'rquv"], "correct_option": 2},
        {"title": "Guruh dinamikasi", "prompt": "Guruhda ko'pchilik bitta odamga qaraydi. U kim ehtimol?", "category": "observation", "options": ["Eng yoshi kichik", "Lider yoki obro'li shaxs", "Eng baland bo'yli", "Eng chiroyli kiyingan"], "correct_option": 1},
    ],
    "medium": [
        {"title": "Mikroifoda", "prompt": "Suhbat chog'ida odam bir zumga labini qimirlatdi va darrov bosdi. Bu nimani bildirishi mumkin?", "category": "body_language", "options": ["Tabassum qilmoqchi edi", "Haqiqiy hissiyotini yashirdi", "Nima deyishini bilmadi", "Ovqat yeyishni istadi"], "correct_option": 1},
        {"title": "Kognitiv yuklama", "prompt": "Kimdir murakkab savol berilganda ko'zini yuqoriga yo'naltirdi. Bu nima uchun?", "category": "psychology", "options": ["Zerikish belgisi", "Yolg'on aytmoqchi", "Ma'lumotni qayta ishlayapti", "Ko'ziga changat tushdi"], "correct_option": 2},
        {"title": "Guruhda kuzatuv", "prompt": "5 ta odamdan iborat guruhda kimdir doim to'g'ridan-to'g'ri eshikka qaraydi. Bu nima uchun?", "category": "observation", "options": ["Eshik chiroyli", "Chiqishni kutmoqda yoki noqulay his etmoqda", "Ko'rish muammosi bor", "Tasodif"], "correct_option": 1},
        {"title": "Muvofiqlik", "prompt": "Suhbatdosh 'ha, albatta' deydi lekin boshi asta-sekin yon tomonga qimirlatadi. Qaysi signalga ishonasiz?", "category": "body_language", "options": ["Og'zaki signalga", "Tana tiliga", "Ikkalasiga teng", "Hech biriga"], "correct_option": 1},
        {"title": "Priming effekti", "prompt": "Do'stingizga 'sariq banana' haqida gapirib, so'ng birinchi sabzavotni so'rasangiz, u ko'pincha nima deydi?", "category": "psychology", "options": ["Pomidor", "Bodring", "Sabzi", "Piyoz"], "correct_option": 2},
        {"title": "Masofa belgisi", "prompt": "Notanish odam siz bilan gaplashganda 40 sm uzoqlikda turadi. Bu qanday zona?", "category": "body_language", "options": ["Shaxsiy zona", "Ijtimoiy zona", "Ommaviy zona", "Yaqin zona"], "correct_option": 1},
        {"title": "O'zgarishni aniqlash", "prompt": "Xonaga har kuni kirasiz. Bir kuni stol oldindan orqasiga surilgan. Buni payqaysizmi?", "category": "observation", "options": ["Ha, darhol payqayman", "Ehtimol payqamayman", "Faqat kimdir aytsa", "Hech qachon payqamayman"], "correct_option": 0},
        {"title": "Hissiy yuqumlilik", "prompt": "Xonaga kirganingizda hamma xafa ko'rinadi. Siz o'zingizni qanday his qilasiz?", "category": "psychology", "options": ["Xursand bo'laman", "Xafa bo'laman, sababsiz", "O'zgarmas qolaman", "Kulaman"], "correct_option": 1},
        {"title": "Diqqat tanlash", "prompt": "Ko'chada yurganingizda noma'qul ovoz eshitdingiz. Siz nima qilasiz?", "category": "observation", "options": ["E'tibor bermayman", "Manbani qidiraman", "Tezroq yuraman", "Telefonim bor"], "correct_option": 1},
        {"title": "Niyat o'qish", "prompt": "Inson do'konda uzoq vaqt bitta narsani ko'rib turadi lekin olmaydi. Nega?", "category": "psychology", "options": ["Yoqmadi", "Puli yo'q yoki qaror qabul qilolmayapti", "Sotuvchini kutmoqda", "Rasmga olmoqda"], "correct_option": 1},
    ],
    "hard": [
        {"title": "Dueland effekti", "prompt": "Inson o'z malakasini past baholaydi, holbuki u sohasida yaxshi mutaxassis. Bu qanday hodisa?", "category": "psychology", "options": ["Dunning-Kruger effekti", "Impostor sindrom", "Konfirmatsiya tarafkashligi", "Sababiy atribut"], "correct_option": 1},
        {"title": "Mikroifodalar ketma-ketligi", "prompt": "Suhbat chog'ida: bosh yuqoriga ko'tarildi → chap qosh ko'tarildi → lab qirishtirилди. Bu ketma-ketlik nimani bildiradi?", "category": "body_language", "options": ["Qiziqish → shubha → rad etish", "Yolg'on → qo'rquv → g'azab", "Hayrat → tanish → tabassum", "Zerikish → fikrlash → kelishuv"], "correct_option": 0},
        {"title": "Kontekstli kuzatuv", "prompt": "Metro stansiyasida 3 odam: biri doimiy soatini ko'radi, ikkinchisi eshikka qaraydi, uchinchisi telefonda. Qaysi biri ehtimol kimnidir kutmoqda?", "category": "observation", "options": ["Soatga qaragan", "Eshikka qaragan", "Telefonidagi", "Barchasi"], "correct_option": 0},
        {"title": "Neyro-lingvistik dasturlash", "prompt": "Odam audial dominant bo'lsa, uning so'zlashuvida qaysi ifodalar ko'proq uchraydi?", "category": "psychology", "options": ["'Ko'raman', 'ravshanroq', 'tasavvur qilaman'", "'Eshitaman', 'yangraydi', 'aytaman'", "'His qilaman', 'og'ir', 'qattiq'", "'Tushunaman', 'anglayman', 'bilaman'"], "correct_option": 1},
        {"title": "Adaptiv maskalash", "prompt": "Professional yolg'onchi suhbatda ko'zni to'g'ridan-to'g'ri tutadi. Bu nima uchun?", "category": "body_language", "options": ["U haqiqatni aytmoqda", "Odatdagi ko'z teginishini taqlid qilyapti", "Ishonch uyg'otmoqchi", "Ko'zi kam ko'radi"], "correct_option": 1},
        {"title": "Guruhda liderlik", "prompt": "Munozarada kimning lider ekanligini eng tez qanday aniqlaysiz?", "category": "observation", "options": ["Eng baland ovozda gapirayotganni", "Boshqalar kim gapirganida o'zlarini qanday tutishiga qarash orqali", "Eng ko'p gapiruvchini", "Eng katta odamni"], "correct_option": 1},
        {"title": "Kognitivdissonans", "prompt": "Kishi o'z qarashlariga zid bo'lgan ma'lumotni eshitganda odatda nima qiladi?", "category": "psychology", "options": ["Darhol fikrni o'zgartiradi", "Rad etadi yoki kamchillik qidiradi", "Qiziqish bilan o'rganadi", "Jim bo'ladi"], "correct_option": 1},
        {"title": "Mikrotitroqlar", "prompt": "Sevimli ovqatini yeyayotganda past darajadagi peshonaning burishishi nimani bildiradi?", "category": "body_language", "options": ["Hech narsa bildirmaydi", "Yashirin norozilik yoki ikkilanish", "Xursandlik", "Toliqish"], "correct_option": 1},
        {"title": "Periferik diqqat", "prompt": "Ko'zingiz to'g'ridan-to'g'ri oldinga qarab turib, nechtadagi ob'ektni bir vaqtda kuzatishingiz mumkin?", "category": "observation", "options": ["1-2 ta", "3-5 ta", "Ko'p — 100°+ burchak doirasidagi hamma narsani", "Faqat markazdagini"], "correct_option": 2},
        {"title": "Ekstremal vaziyatda qaror", "prompt": "Hodisa joyida 10 kishidan 8 tasi bir yo'lda ketmoqda. To'g'ri qaror qilish uchun qaysi omil muhimroq?", "category": "psychology", "options": ["Ko'pchilikning yo'lidan borish", "Vaziyatni mustaqil baholash va teskari yo'l ham ko'rib chiqish", "Eng ishonchli ko'rinadigan kishiga ergashish", "Harakatsiz kutish"], "correct_option": 1},
    ],
}


async def generate_tests(difficulty: Literal["easy", "medium", "hard"]) -> list[dict]:
    """Generate 10 observation tests via AI. Falls back to static tests if AI unavailable."""
    hint = _DIFFICULTY_HINTS.get(difficulty, _DIFFICULTY_HINTS["medium"])
    user_prompt = (
        f"Qiyinlik darajasi: {difficulty}\n{hint}\n\n"
        "Aynan 10 ta test yarating:\n"
        "- 4 ta psychology (psixologiya)\n"
        "- 3 ta body_language (tana tili)\n"
        "- 3 ta observation (kuzatuvchanlik)\n"
        "Har bir savol o'ziga xos va qiziqarli bo'lsin."
    )

    result = await structured_completion(
        system=_SYSTEM,
        user=user_prompt,
        tool_name="generate_observation_tests",
        tool_description="Kuzatuvchanlik testlarini yaratish va qaytarish.",
        input_schema=_SCHEMA,
        max_tokens=4000,
    )

    tests: list[dict]
    if result and result.get("tests"):
        tests = result["tests"]
    else:
        tests = [t.copy() for t in _FALLBACK.get(difficulty, _FALLBACK["medium"])]

    for i, t in enumerate(tests):
        t["id"] = str(uuid.uuid4())
        t["order_index"] = i
        t.setdefault("media_type", "image")
        t.setdefault("media_url", None)

    return tests
