import { Check, Eye, Mic, Sparkles } from "lucide-react";
import CTAButton from "./CTAButton";
import PhoneMockup from "./PhoneMockup";

export default function Hero() {
  return (
    <section className="relative overflow-hidden">
      {/* Animated decorative blobs */}
      <div className="animate-blob pointer-events-none absolute -top-24 right-[-8%] h-96 w-96 rounded-full bg-wine-100/60 blur-3xl" />
      <div className="animate-blob-reverse pointer-events-none absolute bottom-0 left-[-10%] h-80 w-80 rounded-full bg-sky-100/70 blur-3xl" />
      <div className="animate-blob pointer-events-none absolute left-1/3 top-1/2 h-64 w-64 rounded-full bg-orange-100/40 blur-3xl [animation-delay:-12s]" />

      <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-12 px-4 pb-16 pt-10 sm:px-6 lg:grid-cols-2 lg:gap-8 lg:pb-24 lg:pt-16">
        {/* Copy column */}
        <div className="text-center lg:text-left">
          <div className="enter mb-5 inline-flex flex-wrap items-center justify-center gap-2 lg:justify-start">
            <span className="btn-shimmer rounded-full bg-gradient-to-r from-wine-600 to-wine-800 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wide text-white shadow-cta">
              Bepul
            </span>
            <span className="inline-flex items-center gap-1.5 rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-bold text-wine-700 ring-1 ring-wine-100">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-orange opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-brand-orange" />
              </span>
              5 daqiqada AI tahlil
            </span>
          </div>

          <h1
            className="enter text-[32px] font-extrabold leading-[1.15] tracking-tight text-ink sm:text-4xl lg:text-[44px]"
            style={{ animationDelay: "120ms" }}
          >
            Nutqingiz va ovozingizni{" "}
            <span className="text-gradient-brand whitespace-nowrap">AI orqali</span> 5 daqiqada
            tekshirib ko‘ring
          </h1>

          <p
            className="enter mx-auto mt-5 max-w-xl text-base leading-relaxed text-neutral-600 sm:text-lg lg:mx-0"
            style={{ animationDelay: "240ms" }}
          >
            NotiqAI ovozingiz, talaffuzingiz, pauzalaringiz, parazit so‘zlaringiz va fikr
            yetkazishingizni tahlil qiladi.
          </p>

          <div
            className="enter mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center lg:justify-start"
            style={{ animationDelay: "360ms" }}
          >
            <CTAButton
              id="hero_primary_cta"
              event="main_cta_click"
              className="btn-shimmer w-full sm:w-auto"
              meta={{ placement: "hero_primary" }}
            >
              <Mic className="h-5 w-5" />
              Bepul tahlil olish
            </CTAButton>
            <CTAButton
              id="hero_secondary_cta"
              event="observation_test_click"
              variant="secondary"
              className="w-full sm:w-auto"
              meta={{ placement: "hero_secondary" }}
            >
              <Eye className="h-5 w-5 text-brand-sky" />
              Kuzatuvchanlik testini topshirish
            </CTAButton>
          </div>

          <p
            className="enter mt-4 flex items-center justify-center gap-1.5 text-sm font-semibold text-neutral-500 lg:justify-start"
            style={{ animationDelay: "480ms" }}
          >
            <Check className="h-4 w-4 text-emerald-500" />
            Ro‘yxatdan o‘tmasdan ham sinab ko‘rish mumkin.
          </p>

          {/* Value chips */}
          <div
            className="enter mt-8 grid max-w-md grid-cols-3 gap-3 border-t border-wine-100/70 pt-6 text-left max-lg:mx-auto"
            style={{ animationDelay: "600ms" }}
          >
            {[
              { big: "5 daqiqa", small: "Tezkor natija" },
              { big: "100% bepul", small: "Ro‘yxatsiz" },
              { big: "AI tahlil", small: "Chuqur diagnostika" },
            ].map((v) => (
              <div key={v.big}>
                <div className="text-gradient-brand text-lg font-extrabold">{v.big}</div>
                <div className="text-[10px] font-bold uppercase tracking-wider text-neutral-400">
                  {v.small}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Mockup column */}
        <div className="enter" style={{ animationDelay: "300ms" }}>
          <PhoneMockup />
          <p className="mt-6 flex items-center justify-center gap-1.5 text-xs font-bold text-neutral-400 lg:hidden">
            <Sparkles className="h-3.5 w-3.5 text-brand-orange" />
            Ilova ichidagi real natija ko‘rinishi
          </p>
        </div>
      </div>
    </section>
  );
}
