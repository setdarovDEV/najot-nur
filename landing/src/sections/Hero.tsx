import { ArrowRight, Sparkles, Mic, Headphones, Eye } from "lucide-react";
import { BRAND } from "../lib/config";

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden bg-gradient-to-b from-paper via-white to-paper">
      <div
        aria-hidden
        className="absolute -top-32 right-[-10%] h-[480px] w-[480px] rounded-full bg-gradient-to-br from-wine/20 via-orange/20 to-skyblue/20 blur-3xl"
      />
      <div
        aria-hidden
        className="absolute -bottom-32 left-[-10%] h-[420px] w-[420px] rounded-full bg-gradient-to-tr from-skyblue/20 to-wine/10 blur-3xl"
      />

      <div className="container-x relative grid gap-12 py-20 md:grid-cols-2 md:py-28">
        <div className="animate-fade-up">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-orange-50 px-3 py-1 text-xs font-bold text-orange">
            <Sparkles size={12} />
            Najot Nur · Notiqlik markazi
          </span>
          <h1 className="mt-5 text-5xl font-extrabold leading-[1.05] tracking-tight md:text-6xl lg:text-7xl">
            So'zlash san'atini{" "}
            <span className="bg-gradient-to-r from-wine to-orange bg-clip-text text-transparent">
              AI bilan
            </span>{" "}
            o'rganing
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-muted">
            NotiqAI — nutqingiz, ovozingiz va kuzatuvchanligingizni sun'iy intellekt
            yordamida tahlil qiladi. Parazit so'zlardan to sahnada o'zini
            tutishgacha — barchasi bitta platformada.
          </p>

          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="#cta"
              className="inline-flex items-center gap-2 rounded-2xl bg-wine px-6 py-3.5 text-sm font-bold text-white shadow-xl shadow-wine/25 transition hover:bg-wine-dark"
            >
              Bepul sinab ko'rish <ArrowRight size={16} />
            </a>
            <a
              href={BRAND.links.api}
              className="inline-flex items-center gap-2 rounded-2xl border border-line bg-white px-6 py-3.5 text-sm font-bold text-ink transition hover:border-wine/30 hover:text-wine"
            >
              API hujjati
            </a>
          </div>

          <div className="mt-10 flex items-center gap-6 text-sm text-muted">
            <div className="flex -space-x-2">
              {["#8A1538", "#FF5C39", "#5BC2E7", "#14181F"].map((c, i) => (
                <span
                  key={i}
                  className="grid h-8 w-8 place-items-center rounded-full border-2 border-paper text-[10px] font-black text-white"
                  style={{ background: c }}
                >
                  {String.fromCharCode(65 + i)}
                </span>
              ))}
            </div>
            <span>
              <strong className="text-ink">5,200+</strong> foydalanuvchi allaqachon
              mashq qilmoqda
            </span>
          </div>
        </div>

        <div className="relative grid place-items-center">
          <div className="relative aspect-square w-full max-w-md">
            <div
              aria-hidden
              className="absolute inset-0 animate-blob bg-gradient-to-br from-wine via-orange to-skyblue opacity-90"
            />
            <div
              aria-hidden
              className="absolute inset-[8%] rounded-full bg-radial-gradient from-white/40 to-transparent"
              style={{
                background:
                  "radial-gradient(circle at 30% 30%, rgba(255,255,255,0.5), transparent 50%)",
              }}
            />

            <FloatCard className="left-[-6%] top-[8%]" delay="0s">
              <div className="text-2xl font-black text-wine">96%</div>
              <div className="text-[11px] font-semibold text-muted">
                Aniqlik · Ovoz tahlili
              </div>
            </FloatCard>

            <FloatCard className="right-[-6%] top-[28%]" delay="1s">
              <div className="flex items-center gap-2">
                <Mic size={14} className="text-wine" />
                <span className="text-sm font-bold text-ink">Nutq 1:42</span>
              </div>
              <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-line">
                <div className="h-full w-3/4 rounded-full bg-gradient-to-r from-wine to-orange" />
              </div>
            </FloatCard>

            <FloatCard className="bottom-[12%] left-[6%]" delay="2s">
              <div className="flex items-center gap-2">
                <Headphones size={14} className="text-skyblue" />
                <span className="text-xs font-bold text-ink">Ekspert ovozi</span>
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
      className={`absolute animate-float rounded-2xl bg-white px-4 py-3 shadow-2xl shadow-wine/10 ${className ?? ""}`}
      style={{ animationDelay: delay }}
    >
      {children}
    </div>
  );
}
