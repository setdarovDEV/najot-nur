import { Star } from "lucide-react";

const items = [
  {
    name: "Dilshod Karimov",
    role: "Tadbirkor",
    text: "NotiqAI yordamida 3 oyda notiqlik qobiliyatim ikki barobar oshdi. Investorlarga taqdimot qilish endi qo'rquv emas.",
  },
  {
    name: "Malika Yusupova",
    role: "O'qituvchi",
    text: "Talabalarim uchun ishlataman. Avtomatik tahlil va kuratorlar — bu g'oya zo'r ishlaydi.",
  },
  {
    name: "Sherzod Toshmatov",
    role: "Marketolog",
    text: "Ekspert ovozi bilan audiokitoblar ajoyib. Har tong mashq qilib boshlayman.",
  },
];

export function Testimonials() {
  return (
    <section className="bg-white py-20 md:py-28">
      <div className="container-x">
        <div className="mx-auto max-w-2xl text-center">
          <span className="text-xs font-bold uppercase tracking-wider text-wine">
            Foydalanuvchilar fikri
          </span>
          <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
            5,200+ foydalanuvchi bizga ishonadi
          </h2>
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {items.map((t) => (
            <figure
              key={t.name}
              className="flex flex-col gap-5 rounded-2xl border border-line bg-paper p-7"
            >
              <div className="flex gap-1 text-orange">
                {[0, 1, 2, 3, 4].map((i) => (
                  <Star key={i} size={16} fill="currentColor" stroke="none" />
                ))}
              </div>
              <blockquote className="flex-1 text-sm leading-relaxed text-ink/85">
                "{t.text}"
              </blockquote>
              <figcaption className="border-t border-line pt-4">
                <div className="text-sm font-extrabold">{t.name}</div>
                <div className="text-xs text-muted">{t.role}</div>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
