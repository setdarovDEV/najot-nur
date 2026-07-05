import { Eye, MessageSquareText, Mic } from "lucide-react";
import { openDemo } from "../lib/device";
import { useReveal } from "../lib/hooks";
import { track, type TrackingEventName } from "../lib/tracking";

interface FeatureCard {
  id: string;
  event: TrackingEventName;
  title: string;
  text: string;
  cta: string;
  icon: typeof Mic;
  iconClass: string;
  barClass: string;
}

const CARDS: FeatureCard[] = [
  {
    id: "feature_speech_cta",
    event: "speech_test_click",
    title: "Nutq tahlili",
    text: "O‘zingiz haqingizda 2 daqiqa gapiring va AI nutqingizni tahlil qiladi.",
    cta: "Nutqimni tekshirish",
    icon: MessageSquareText,
    iconClass: "bg-wine-50 text-wine-700",
    barClass: "from-wine-600 to-wine-400",
  },
  {
    id: "feature_voice_cta",
    event: "voice_test_click",
    title: "Ovozni tekshirish",
    text: "Berilgan matnni o‘qing va AI talaffuz, ohang va aniqlik bo‘yicha baho beradi.",
    cta: "Matnni o‘qish",
    icon: Mic,
    iconClass: "bg-orange-50 text-brand-orange",
    barClass: "from-brand-orange to-orange-300",
  },
  {
    id: "feature_observation_cta",
    event: "observation_test_click",
    title: "Kuzatuvchanlik testi",
    text: "Insonlarning tana tili va mimikasini qanchalik yaxshi tushunishingizni tekshiring.",
    cta: "Testni boshlash",
    icon: Eye,
    iconClass: "bg-gradient-to-br from-sky-100 to-violet-100 text-sky-600",
    barClass: "from-brand-sky to-violet-400",
  },
];

export default function Features() {
  const { ref, visible } = useReveal();

  return (
    <section className="py-14 sm:py-20">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div
          ref={ref}
          className={`reveal ${visible ? "is-visible" : ""}`}
        >
          <div className="reveal-item text-center">
            <span className="rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-wine-700 ring-1 ring-wine-100">
              Sizga taklifimiz
            </span>
            <h2 className="mt-4 text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">
              Bugun 3 ta narsani <span className="text-gradient-brand">bepul</span> sinab ko‘ring
            </h2>
          </div>

          <div className="mt-10 grid grid-cols-1 gap-5 md:grid-cols-3">
            {CARDS.map((card, i) => (
              <button
                key={card.id}
                id={card.id}
                onClick={() => {
                  track(card.event, { button_id: card.id, placement: "features" });
                  openDemo();
                }}
                className="reveal-item card-premium group relative overflow-hidden p-6 shadow-card text-left"
                style={{ "--d": `${150 + i * 150}ms` } as React.CSSProperties}
              >
                {/* Top accent bar */}
                <span
                  className={`absolute inset-x-0 top-0 h-1.5 origin-left scale-x-0 bg-gradient-to-r transition-transform duration-500 group-hover:scale-x-100 ${card.barClass}`}
                />
                <div
                  className={`mb-5 flex h-14 w-14 items-center justify-center rounded-2xl transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6 ${card.iconClass}`}
                >
                  <card.icon className="h-7 w-7" />
                </div>
                <h3 className="text-lg font-extrabold text-ink">{card.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-neutral-600">{card.text}</p>
                <span className="mt-4 inline-flex items-center gap-1 text-sm font-bold text-wine-700 transition-transform duration-300 group-hover:translate-x-1.5">
                  {card.cta} →
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
