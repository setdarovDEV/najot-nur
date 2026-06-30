import { Star, Quote } from "lucide-react";
import { useReveal } from "../lib/hooks";

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
  const { ref, visible } = useReveal<HTMLDivElement>();
  return (
    <section className="bg-white py-20 md:py-28">
      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-wine">
              Foydalanuvchilar fikri
            </span>
            <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
              5,300+ foydalanuvchi bizga ishonadi
            </h2>
          </div>

          <div className="mt-14 grid gap-6 md:grid-cols-3">
            {items.map((t, i) => (
              <figure
                key={t.name}
                className="group relative flex flex-col gap-5 overflow-hidden rounded-2xl border border-line bg-paper p-7 transition hover:-translate-y-1 hover:border-wine/30 hover:shadow-xl hover:shadow-wine/5"
                style={{
                  animation: `fade-up 0.7s ${i * 0.12}s ease-out both`,
                }}
              >
                <Quote
                  aria-hidden
                  size={36}
                  className="absolute -right-2 -top-2 text-wine/10 transition group-hover:text-wine/20 group-hover:scale-110"
                />
                <div className="flex gap-1 text-orange">
                  {[0, 1, 2, 3, 4].map((i) => (
                    <Star
                      key={i}
                      size={16}
                      fill="currentColor"
                      stroke="none"
                      className="transition hover:scale-125"
                    />
                  ))}
                </div>
                <blockquote className="flex-1 text-sm leading-relaxed text-ink/85">
                  "{t.text}"
                </blockquote>
                <figcaption className="border-t border-line pt-4">
                  <div className="flex items-center gap-3">
                    <span
                      className="grid h-9 w-9 place-items-center rounded-full bg-gradient-to-br from-wine to-orange text-xs font-black text-white"
                    >
                      {t.name[0]}
                    </span>
                    <div>
                      <div className="text-sm font-extrabold">{t.name}</div>
                      <div className="text-xs text-muted">{t.role}</div>
                    </div>
                  </div>
                </figcaption>
              </figure>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
