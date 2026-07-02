import { BrainCircuit, ListChecks, Mic } from "lucide-react";
import { useReveal } from "../lib/hooks";

const STEPS = [
  {
    title: "Test turini tanlang",
    text: "Nutq tahlili, ovoz tekshiruvi yoki kuzatuvchanlik testini tanlaysiz.",
    icon: ListChecks,
  },
  {
    title: "2 daqiqa gapiring yoki matnni o‘qing",
    text: "Berilgan topshiriqni telefoningizda bemalol bajarasiz.",
    icon: Mic,
  },
  {
    title: "AI tahlilini oling",
    text: "Qisqa vaqt ichida natija, ball va shaxsiy tavsiyalarni ko‘rasiz.",
    icon: BrainCircuit,
  },
];

export default function HowItWorks() {
  const { ref, visible } = useReveal();

  return (
    <section className="bg-white py-14 sm:py-20">
      <div
        ref={ref}
        className={`reveal mx-auto max-w-5xl px-4 sm:px-6 ${visible ? "is-visible" : ""}`}
      >
        <div className="reveal-item text-center">
          <span className="rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-wine-700 ring-1 ring-wine-100">
            3 oddiy qadam
          </span>
          <h2 className="mt-4 text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">
            Qanday ishlaydi?
          </h2>
        </div>

        <div className="relative mt-12 grid grid-cols-1 gap-10 md:grid-cols-3 md:gap-8">
          {/* Marching dashed connector (desktop) */}
          <svg
            className="absolute left-[16%] right-[16%] top-8 hidden h-2 w-[68%] md:block"
            preserveAspectRatio="none"
            viewBox="0 0 100 2"
            aria-hidden
          >
            <line
              x1="0"
              y1="1"
              x2="100"
              y2="1"
              stroke="var(--color-wine-300)"
              strokeWidth="2"
              className="dash-march"
              vectorEffect="non-scaling-stroke"
            />
          </svg>

          {STEPS.map((step, i) => (
            <div
              key={step.title}
              className="reveal-item relative flex flex-col items-center text-center"
              style={{ "--d": `${200 + i * 220}ms` } as React.CSSProperties}
            >
              <div className="group relative z-10">
                <span className="animate-pulse-ring absolute inset-0 rounded-3xl bg-wine-300 [animation-delay:var(--pd)]" style={{ "--pd": `${i * 0.8}s` } as React.CSSProperties} />
                <div className="relative flex h-16 w-16 items-center justify-center rounded-3xl bg-gradient-to-br from-wine-600 to-wine-800 text-white shadow-cta transition-transform duration-300 hover:scale-110 hover:-rotate-3">
                  <step.icon className="h-7 w-7" />
                  <span className="absolute -right-1.5 -top-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-brand-orange text-xs font-extrabold text-white shadow-md">
                    {i + 1}
                  </span>
                </div>
              </div>
              <h3 className="mt-5 text-base font-extrabold text-ink">{step.title}</h3>
              <p className="mt-2 max-w-xs text-sm leading-relaxed text-neutral-600">{step.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
