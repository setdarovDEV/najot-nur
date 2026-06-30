import { ArrowRight, Sparkles, Mic, Headphones, Eye, Play } from "lucide-react";
import { BRAND } from "../lib/config";
import { useReveal } from "../lib/hooks";

export function Hero() {
  const { ref: leftRef, visible: leftV } = useReveal<HTMLDivElement>();
  const { ref: rightRef, visible: rightV } = useReveal<HTMLDivElement>();

  return (
    <section id="top" className="relative overflow-hidden bg-gradient-to-b from-paper via-white to-paper">
      <div
        aria-hidden
        className="absolute -top-40 right-[-10%] h-[520px] w-[520px] animate-blob rounded-full bg-gradient-to-br from-wine/20 via-orange/20 to-skyblue/20 blur-3xl"
      />
      <div
        aria-hidden
        className="absolute -bottom-40 left-[-12%] h-[460px] w-[460px] animate-blob rounded-full bg-gradient-to-tr from-skyblue/25 to-wine/10 blur-3xl"
        style={{ animationDelay: "4s" }}
      />
      <div
        aria-hidden
        className="absolute left-1/3 top-1/2 h-2 w-2 animate-pulse-ring rounded-full bg-wine/40"
      />
      <div
        aria-hidden
        className="absolute right-1/4 top-1/3 h-2 w-2 animate-pulse-ring rounded-full bg-orange/40"
        style={{ animationDelay: "1.2s" }}
      />

      <div className="container-x relative grid gap-12 py-20 md:grid-cols-2 md:py-28">
        <div ref={leftRef} className={`reveal ${leftV ? "is-visible" : ""}`}>
          <span className="inline-flex items-center gap-1.5 rounded-full border border-wine/15 bg-wine-50/80 px-3 py-1 text-xs font-bold text-wine animate-fade-in">
            <Sparkles size={12} className="animate-wiggle" />
            Najot Nur · Notiqlik markazi
          </span>
          <h1 className="mt-5 text-5xl font-extrabold leading-[1.05] tracking-tight md:text-6xl lg:text-7xl">
            So'zlash san'atini{" "}
            <span className="shimmer-text">AI bilan</span>{" "}
            o'rganing
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-muted">
            NotiqAI — <strong className="text-ink">Najot Nur</strong> tajribasi va
            sun'iy intellekt quvvati birlashtirilgan platforma. Nutqingiz, ovozingiz
            va kuzatuvchanligingizni tahlil qiling — har bir mashg'ulotda aniq
            tavsiyalar.
          </p>

          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="#cta"
              className="group inline-flex items-center gap-2 rounded-2xl bg-wine px-6 py-3.5 text-sm font-bold text-white shadow-xl shadow-wine/25 transition hover:scale-[1.02] hover:bg-wine-dark hover:shadow-wine/40"
            >
              Bepul sinab ko'rish
              <ArrowRight size={16} className="transition group-hover:translate-x-1" />
            </a>
            <a
              href={BRAND.links.api}
              className="group inline-flex items-center gap-2 rounded-2xl border border-line bg-white px-6 py-3.5 text-sm font-bold text-ink transition hover:scale-[1.02] hover:border-wine/30 hover:text-wine"
            >
              <Play size={14} className="fill-current" />
              API hujjati
            </a>
          </div>

          <div className="mt-10 flex items-center gap-6 text-sm text-muted">
            <div className="flex -space-x-2">
              {["#8A1538", "#FF5C39", "#5BC2E7", "#14181F"].map((c, i) => (
                <span
                  key={i}
                  className="grid h-8 w-8 place-items-center rounded-full border-2 border-paper text-[10px] font-black text-white transition hover:scale-110 hover:z-10"
                  style={{ background: c, animationDelay: `${i * 0.1}s` }}
                >
                  {String.fromCharCode(65 + i)}
                </span>
              ))}
            </div>
            <span>
              <strong className="text-ink">5,300+</strong> foydalanuvchi allaqachon
              mashq qilmoqda
            </span>
          </div>
        </div>

        <div ref={rightRef} className={`relative grid place-items-center reveal-scale ${rightV ? "is-visible" : ""}`}>
          <div className="relative aspect-square w-full max-w-md">
            <div
              aria-hidden
              className="absolute inset-0 animate-blob bg-gradient-to-br from-wine via-orange to-skyblue opacity-90"
            />
            <div
              aria-hidden
              className="absolute inset-0 animate-blob bg-gradient-to-tr from-orange/40 to-skyblue/40 mix-blend-overlay"
              style={{ animationDelay: "2s" }}
            />
            <div
              aria-hidden
              className="absolute inset-[8%] rounded-full"
              style={{
                background:
                  "radial-gradient(circle at 30% 30%, rgba(255,255,255,0.5), transparent 50%)",
              }}
            />

            <div
              aria-hidden
              className="absolute left-1/2 top-1/2 -z-10 h-[120%] w-[120%] -translate-x-1/2 -translate-y-1/2 animate-spin-slow"
            >
              <svg viewBox="0 0 200 200" className="h-full w-full opacity-30">
                <defs>
                  <path id="circle-path" d="M 100,100 m -80,0 a 80,80 0 1,1 160,0 a 80,80 0 1,1 -160,0" />
                </defs>
                <text fontSize="11" fontWeight="700" fill="#8A1538" letterSpacing="3">
                  <textPath href="#circle-path">
                    NOTIQ · AI · NOTIQLIK · NUTQ · OVOZ · NOTIQ · AI ·
                  </textPath>
                </text>
              </svg>
            </div>

            <FloatCard className="left-[-6%] top-[8%]" delay="0s">
              <div className="text-2xl font-black text-wine">96%</div>
              <div className="text-[11px] font-semibold text-muted">
                Aniqlik · Ovoz tahlili
              </div>
            </FloatCard>

            <FloatCard className="right-[-6%] top-[28%]" delay="1s">
              <div className="flex items-center gap-2">
                <Mic size={14} className="text-wine animate-wiggle" />
                <span className="text-sm font-bold text-ink">Nutq 1:42</span>
              </div>
              <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-line">
                <div className="h-full w-3/4 rounded-full bg-gradient-to-r from-wine to-orange" />
              </div>
              <div className="mt-1.5 flex items-end gap-0.5">
                <span className="block w-1 origin-bottom rounded-sm bg-wine/70 animate-wave-1" style={{ height: "10px" }} />
                <span className="block w-1 origin-bottom rounded-sm bg-wine/70 animate-wave-2" style={{ height: "14px" }} />
                <span className="block w-1 origin-bottom rounded-sm bg-wine/70 animate-wave-3" style={{ height: "8px" }} />
                <span className="block w-1 origin-bottom rounded-sm bg-wine/70 animate-wave-4" style={{ height: "12px" }} />
                <span className="block w-1 origin-bottom rounded-sm bg-orange animate-wave-5" style={{ height: "16px" }} />
              </div>
            </FloatCard>

            <FloatCard className="bottom-[12%] left-[6%]" delay="2s">
              <div className="flex items-center gap-2">
                <Headphones size={14} className="text-skyblue" />
                <span className="text-xs font-bold text-ink">Ekspert ovozi</span>
              </div>
              <div className="mt-1.5 flex items-center gap-1">
                <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-skyblue" />
                <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-skyblue" style={{ animationDelay: "0.2s" }} />
                <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-skyblue" style={{ animationDelay: "0.4s" }} />
                <span className="text-[10px] font-semibold text-muted">● jonli</span>
              </div>
            </FloatCard>

            <FloatCard className="bottom-[6%] right-[2%]" delay="0.5s">
              <div className="flex items-center gap-2">
                <Eye size={14} className="text-orange" />
                <span className="text-xs font-bold text-ink">10 ta test topshiring</span>
              </div>
            </FloatCard>
          </div>
        </div>
      </div>

      <div
        aria-hidden
        className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-wine/20 to-transparent"
      />
    </section>
  );
}

function FloatCard({
  className,
  delay = "0s",
  children,
}: {
  className?: string;
  delay?: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className={`absolute animate-float rounded-2xl bg-white px-4 py-3 shadow-2xl shadow-wine/10 transition hover:scale-105 hover:shadow-wine/30 ${className ?? ""}`}
      style={{ animationDelay: delay }}
    >
      {children}
    </div>
  );
}
