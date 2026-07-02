import { CheckCircle2, Mic } from "lucide-react";
import CTAButton from "./CTAButton";
import { useReveal } from "../lib/hooks";

const RESULTS = [
  "Ovozingiz qanchalik ishonchli eshitilishi",
  "Nutqingizdagi pauza va parazit so‘zlar",
  "Fikrlaringiz qanchalik tartibli yetkazilishi",
  "Talaffuzingizdagi xatolar",
  "Kuzatuvchanlik darajangiz",
];

export default function Results() {
  const { ref, visible } = useReveal();

  return (
    <section className="bg-gradient-animated relative overflow-hidden py-14 text-white sm:py-20">
      {/* Glow orbs */}
      <div className="animate-blob pointer-events-none absolute -left-20 top-0 h-72 w-72 rounded-full bg-wine-400/20 blur-3xl" />
      <div className="animate-blob-reverse pointer-events-none absolute -right-16 bottom-0 h-80 w-80 rounded-full bg-brand-orange/15 blur-3xl" />

      <div
        ref={ref}
        className={`reveal relative mx-auto grid max-w-5xl grid-cols-1 items-center gap-10 px-4 sm:px-6 lg:grid-cols-2 ${visible ? "is-visible" : ""}`}
      >
        <div className="reveal-item reveal-item-left text-center lg:text-left">
          <span className="rounded-full bg-white/10 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-white/80 ring-1 ring-white/20">
            Sizning natijangiz
          </span>
          <h2 className="mt-4 text-2xl font-extrabold tracking-tight sm:text-3xl">
            5 daqiqadan keyin nimalarni bilasiz?
          </h2>
          <p className="mt-4 text-base leading-relaxed text-white/75">
            Qisqa test yakunida AI sizga aniq ball, xatolar ro‘yxati va amaliy tavsiyalar bilan
            shaxsiy hisobot taqdim etadi.
          </p>
          <div className="mt-7 max-lg:flex max-lg:justify-center">
            <CTAButton
              id="results_cta"
              event="main_cta_click"
              variant="inverse"
              size="md"
              meta={{ placement: "results" }}
            >
              <Mic className="h-4.5 w-4.5" />
              O‘z natijamni bilish
            </CTAButton>
          </div>
        </div>

        <ul className="space-y-3">
          {RESULTS.map((item, i) => (
            <li
              key={item}
              className="reveal-item reveal-item-right flex items-center gap-3 rounded-2xl bg-white/10 px-5 py-4 ring-1 ring-white/10 backdrop-blur-sm transition-colors hover:bg-white/15"
              style={{ "--d": `${120 + i * 120}ms` } as React.CSSProperties}
            >
              <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-300" />
              <span className="text-sm font-semibold sm:text-base">{item}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
