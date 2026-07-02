import { CheckCircle2, XCircle } from "lucide-react";
import { useReveal } from "../lib/hooks";

const BEFORE = [
  "Har gapda “haligi”, “xo‘sh” kabi parazit so‘zlar",
  "Ortiqcha pauzalar va ishonchsiz, past ovoz",
  "Fikrni chalkash, tartibsiz yetkazish",
];

const AFTER = [
  "Toza, parazit so‘zlarsiz ravon nutq",
  "Ishonch uyg‘otadigan barqaror ohang",
  "Mantiqiy izchil va ta’sirli bayon",
];

export default function Problem() {
  const { ref, visible } = useReveal();

  return (
    <section className="relative overflow-hidden bg-white py-14 sm:py-20">
      <div className="animate-blob pointer-events-none absolute -right-24 top-0 h-72 w-72 rounded-full bg-wine-50 blur-3xl" />

      <div
        ref={ref}
        className={`reveal relative mx-auto max-w-5xl px-4 sm:px-6 ${visible ? "is-visible" : ""}`}
      >
        <div className="reveal-item mx-auto max-w-2xl text-center">
          <span className="rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-wine-700 ring-1 ring-wine-100">
            Muammo nimada?
          </span>
          <h2 className="mt-4 text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">
            Gapirish oson. <span className="text-gradient-brand">Ta’sirli gapirish</span> esa
            alohida ko‘nikma.
          </h2>
          <p className="mt-4 text-base leading-relaxed text-neutral-600">
            Ko‘pchilik odamlar o‘z nutqidagi xatolarni sezmaydi: ortiqcha pauzalar, parazit
            so‘zlar, ishonchsiz ovoz yoki fikrni chalkash yetkazish. NotiqAI sizga nutqingizni
            chetdan ko‘rgandek baholashga yordam beradi.
          </p>
        </div>

        {/* Before / After comparison */}
        <div className="mt-10 grid grid-cols-1 gap-5 md:grid-cols-2">
          <div className="reveal-item reveal-item-left rounded-3xl border border-neutral-100 bg-neutral-50/70 p-6" style={{ "--d": "150ms" } as React.CSSProperties}>
            <span className="text-xs font-extrabold uppercase tracking-wider text-neutral-400">
              Odatdagi nutq
            </span>
            <ul className="mt-4 space-y-3">
              {BEFORE.map((item) => (
                <li key={item} className="flex items-start gap-2.5 text-sm font-semibold text-neutral-500">
                  <XCircle className="mt-0.5 h-4.5 w-4.5 shrink-0 text-neutral-300" />
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <div className="reveal-item reveal-item-right bg-gradient-animated rounded-3xl p-6 text-white shadow-cta" style={{ "--d": "300ms" } as React.CSSProperties}>
            <span className="text-xs font-extrabold uppercase tracking-wider text-white/70">
              NotiqAI tahlilidan so‘ng
            </span>
            <ul className="mt-4 space-y-3">
              {AFTER.map((item) => (
                <li key={item} className="flex items-start gap-2.5 text-sm font-bold">
                  <CheckCircle2 className="mt-0.5 h-4.5 w-4.5 shrink-0 text-emerald-300" />
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
