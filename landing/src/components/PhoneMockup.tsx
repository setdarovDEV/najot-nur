import { ChevronLeft, Mic, Sparkles, TrendingUp } from "lucide-react";
import { useCountUp, useReveal, useTilt } from "../lib/hooks";

const METRICS = [
  { label: "Ovoz ishonchliligi", score: 88, color: "bg-wine-600" },
  { label: "Pauzalar balansi", score: 82, color: "bg-brand-sky" },
  { label: "Parazit so‘zlar", score: 75, color: "bg-brand-orange" },
  { label: "Fikr izchilligi", score: 91, color: "bg-emerald-500" },
];

const WAVE_BARS = [38, 62, 84, 52, 96, 70, 44, 88, 58, 76, 40, 66, 92, 50, 34];

const RING_LENGTH = 169.6; // 2πr, r=27

/**
 * CSS-built NotiqAI app screen (speech-analysis result) inside a phone frame —
 * TZ section 10 asks for a realistic app mockup without heavy image assets.
 * Floats, tilts toward the cursor and draws the score ring on reveal.
 */
export default function PhoneMockup() {
  const { ref, visible } = useReveal({ threshold: 0.3 });
  const tiltRef = useTilt<HTMLDivElement>(6);
  const score = useCountUp(84, 1800, visible);

  return (
    <div ref={ref} className={`tilt-wrap relative mx-auto w-[290px] sm:w-[310px] ${visible ? "is-visible" : ""}`}>
      {/* Rotating conic halo */}
      <div className="animate-spin-slow pointer-events-none absolute -inset-10 rounded-full bg-[conic-gradient(from_0deg,rgba(139,15,58,0.16),rgba(91,194,231,0.14),rgba(255,92,57,0.12),rgba(139,15,58,0.16))] blur-2xl" />
      <div className="pointer-events-none absolute -inset-6 rounded-full bg-gradient-to-tr from-wine-200/50 via-wine-100/30 to-sky-100/50 blur-3xl" />

      {/* Floating chips */}
      <div className="animate-float absolute -left-10 top-20 z-20 hidden rounded-2xl bg-white/90 px-3.5 py-2.5 shadow-soft ring-1 ring-wine-100 backdrop-blur-sm sm:block">
        <div className="text-[10px] font-semibold text-neutral-500">Umumiy ball</div>
        <div className="text-base font-extrabold text-wine-700">{score} / 100</div>
      </div>
      <div className="animate-float-slow absolute -right-8 bottom-36 z-20 hidden items-center gap-1.5 rounded-2xl bg-white/90 px-3.5 py-2.5 shadow-soft ring-1 ring-sky-100 backdrop-blur-sm sm:flex">
        <Sparkles className="h-3.5 w-3.5 text-brand-orange" />
        <span className="text-[11px] font-bold text-ink">AI tavsiyalari tayyor</span>
      </div>
      <div className="animate-bounce-soft absolute -right-4 top-10 z-20 hidden items-center gap-1 rounded-full bg-gradient-to-r from-wine-600 to-wine-800 px-3 py-1.5 text-[10px] font-extrabold text-white shadow-cta sm:flex">
        <TrendingUp className="h-3 w-3" />
        +12% ishonch
      </div>

      {/* Frame (tilt target) */}
      <div ref={tiltRef} className="tilt-card animate-float relative z-10">
        <div className="rounded-[3rem] border-[10px] border-ink bg-ink shadow-2xl">
          <div className="overflow-hidden rounded-[2.4rem] bg-paper">
            {/* Status bar */}
            <div className="flex items-center justify-between px-6 pb-1 pt-3 text-[10px] font-bold text-ink">
              <span>9:41</span>
              <div className="h-5 w-24 rounded-full bg-ink" />
              <span>100%</span>
            </div>

            {/* App header */}
            <div className="flex items-center justify-between px-5 py-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-wine-50 text-wine-700">
                <ChevronLeft className="h-4 w-4" />
              </div>
              <span className="text-sm font-extrabold text-ink">Nutq tahlili</span>
              <img src="/logo-nn.png" alt="Najot Nur" className="h-8 w-auto" />
            </div>

            {/* Score card */}
            <div className="bg-gradient-animated mx-4 rounded-3xl p-4 text-white shadow-cta">
              <div className="flex items-center gap-4">
                <div className="relative flex h-16 w-16 shrink-0 items-center justify-center">
                  <svg viewBox="0 0 64 64" className="h-16 w-16 -rotate-90">
                    <circle cx="32" cy="32" r="27" fill="none" stroke="rgba(255,255,255,0.2)" strokeWidth="6" />
                    <circle
                      className="ring-progress"
                      cx="32"
                      cy="32"
                      r="27"
                      fill="none"
                      stroke="#fff"
                      strokeWidth="6"
                      strokeLinecap="round"
                      strokeDasharray={RING_LENGTH}
                      strokeDashoffset={visible ? RING_LENGTH * (1 - 0.84) : RING_LENGTH}
                    />
                  </svg>
                  <span className="absolute text-lg font-extrabold">{score}</span>
                </div>
                <div>
                  <div className="text-[13px] font-extrabold">A’lo darajadagi natija!</div>
                  <p className="mt-0.5 text-[10.5px] leading-snug text-white/75">
                    Ovozingiz ishonchli. Parazit so‘zlarni kamaytirsangiz — mukammal.
                  </p>
                </div>
              </div>
            </div>

            {/* Waveform */}
            <div className="mx-4 mt-3 flex h-14 items-center justify-center gap-1 rounded-2xl bg-white px-4 shadow-card">
              {WAVE_BARS.map((h, i) => (
                <span
                  key={i}
                  className="animate-wave w-1 rounded-full bg-gradient-to-t from-wine-700 to-wine-400"
                  style={{ height: `${h}%`, animationDelay: `${i * 90}ms` }}
                />
              ))}
            </div>

            {/* Metrics */}
            <div className="mx-4 mt-3 space-y-2.5 rounded-2xl bg-white p-4 shadow-card">
              {METRICS.map((m, i) => (
                <div key={m.label}>
                  <div className="mb-1 flex items-center justify-between text-[10.5px] font-bold">
                    <span className="text-neutral-600">{m.label}</span>
                    <span className="text-ink">{m.score}%</span>
                  </div>
                  <div className="h-1.5 overflow-hidden rounded-full bg-neutral-100">
                    <div
                      className={`h-full rounded-full ${m.color}`}
                      style={{
                        width: visible ? `${m.score}%` : "0%",
                        transition: `width 1.2s cubic-bezier(0.22,1,0.36,1) ${400 + i * 180}ms`,
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>

            {/* Mic button with pulse rings */}
            <div className="flex justify-center py-4">
              <div className="relative">
                <span className="animate-pulse-ring absolute inset-0 rounded-full bg-wine-400" />
                <div className="relative flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-wine-600 to-wine-800 text-white shadow-cta ring-8 ring-wine-100/70">
                  <Mic className="h-6 w-6" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
