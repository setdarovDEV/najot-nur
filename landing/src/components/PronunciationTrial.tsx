import { Mic } from "lucide-react";
import { openDemo } from "../lib/device";
import { useReveal } from "../lib/hooks";

const EXERCISES = [
  {
    id: "easy",
    level: "Oson",
    badge: "bg-emerald-100 text-emerald-700",
    border: "hover:border-emerald-300",
    icon: "🟢",
    preview:
      "Salom! Mening ismim … Men bugun o'zim haqimda qisqacha gapirib bermoqchiman.",
  },
  {
    id: "medium",
    level: "O'rta",
    badge: "bg-sky-100 text-sky-700",
    border: "hover:border-sky-300",
    icon: "🔵",
    preview:
      "Nutqimizni rivojlantirish uchun har kuni mashq qilish zarur. To'g'ri nafas olish…",
  },
  {
    id: "hard",
    level: "Qiyin",
    badge: "bg-wine-100 text-wine-700",
    border: "hover:border-wine-300",
    icon: "🔴",
    preview:
      "Notiqlik san'ati — bu nafaqat to'g'ri talaffuz, balki tinglovchini o'zingizga jalb eta bilish…",
  },
];

export default function PronunciationTrial() {
  const { ref, visible } = useReveal();

  return (
    <section
      id="sinab-korish"
      className="bg-gradient-to-b from-white to-wine-50/40 py-14 sm:py-20"
    >
      <div
        ref={ref}
        className={`reveal mx-auto max-w-5xl px-4 sm:px-6 ${visible ? "is-visible" : ""}`}
      >
        {/* Heading */}
        <div className="reveal-item text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-wine-700 ring-1 ring-wine-100">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-orange opacity-75" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-brand-orange" />
            </span>
            Bepul sinab ko'ring
          </span>
          <h2 className="mt-4 text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">
            Talaffuz mashqini hoziroq sinab ko'ring
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-sm leading-relaxed text-neutral-500 sm:text-base">
            Matnni o'qing, AI tahlil qiladi. To'liq natijani ilovada ko'ring.
          </p>
        </div>

        {/* Exercise cards */}
        <div className="mt-10 grid grid-cols-1 gap-5 sm:grid-cols-3">
          {EXERCISES.map((ex, i) => (
            <button
              key={ex.id}
              onClick={() => openDemo(ex.id)}
              className={`reveal-item card-premium group relative overflow-hidden p-5 text-left shadow-card transition hover:-translate-y-1 ${ex.border}`}
              style={{ "--d": `${150 + i * 150}ms` } as React.CSSProperties}
            >
              {/* Hover accent bar */}
              <span className="absolute inset-x-0 top-0 h-1 scale-x-0 bg-gradient-to-r from-wine-600 to-wine-400 transition-transform duration-300 group-hover:scale-x-100 origin-left" />

              <div className="mb-3 flex items-center justify-between">
                <span
                  className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold uppercase tracking-wider ${ex.badge}`}
                >
                  {ex.level}
                </span>
                <span className="text-base">{ex.icon}</span>
              </div>

              <p className="text-sm leading-relaxed text-neutral-600 line-clamp-3">
                "{ex.preview}"
              </p>

              <div className="mt-4 flex items-center gap-1.5 text-sm font-bold text-wine-700 transition-transform duration-300 group-hover:translate-x-1">
                <Mic className="h-4 w-4" />
                Sinab ko'rish
              </div>
            </button>
          ))}
        </div>

        {/* Big CTA */}
        <div className="reveal-item mt-8 text-center" style={{ "--d": "600ms" } as React.CSSProperties}>
          <button
            onClick={() => openDemo()}
            className="btn-shimmer inline-flex items-center gap-2 rounded-2xl bg-gradient-to-br from-wine-600 to-wine-800 px-8 py-4 text-base font-bold text-white shadow-cta transition hover:from-wine-500 hover:to-wine-700 hover:-translate-y-0.5 active:scale-[0.98]"
          >
            <Mic className="h-5 w-5" />
            Bepul boshlash
          </button>
          <p className="mt-3 text-xs font-semibold text-neutral-400">
            Ro'yxatdan o'tish yo'q · Mutlaqo bepul · 5 daqiqada natija
          </p>
        </div>
      </div>
    </section>
  );
}
