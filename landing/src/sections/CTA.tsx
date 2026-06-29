import { ArrowRight, Smartphone } from "lucide-react";
import { BRAND } from "../lib/config";

export function CTA() {
  return (
    <section id="cta" className="bg-white py-20 md:py-28">
      <div className="container-x">
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-wine via-wine-dark to-wine-deep p-10 text-white md:p-16">
          <div
            aria-hidden
            className="absolute -right-32 -top-32 h-80 w-80 rounded-full bg-orange/30 blur-3xl"
          />
          <div
            aria-hidden
            className="absolute -bottom-32 -left-32 h-80 w-80 rounded-full bg-skyblue/30 blur-3xl"
          />

          <div className="relative grid items-center gap-10 md:grid-cols-2">
            <div>
              <span className="inline-block rounded-full bg-white/15 px-3 py-1 text-xs font-bold uppercase tracking-wider">
                Bepul sinab ko'ring
              </span>
              <h2 className="mt-4 text-3xl font-extrabold leading-tight md:text-5xl">
                Birinchi mashg'ulotni bugun boshlang
              </h2>
              <p className="mt-4 max-w-md text-base text-white/85">
                5 daqiqada ro'yxatdan o'ting va AI yordamida nutqingizni
                tahlil qiling. Karta talab qilinmaydi.
              </p>

              <div className="mt-8 flex flex-wrap gap-3">
                <a
                  href={BRAND.links.playMarket}
                  className="inline-flex items-center gap-2.5 rounded-2xl bg-white px-5 py-3 text-sm font-bold text-wine transition hover:bg-paper"
                >
                  <Smartphone size={18} />
                  Google Play
                </a>
                <a
                  href={BRAND.links.appStore}
                  className="inline-flex items-center gap-2.5 rounded-2xl border border-white/30 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  <Smartphone size={18} />
                  App Store
                </a>
                <a
                  href="#contact"
                  className="inline-flex items-center gap-2.5 rounded-2xl border border-white/30 px-5 py-3 text-sm font-bold text-white transition hover:bg-white/10"
                >
                  Bog'lanish <ArrowRight size={16} />
                </a>
              </div>
            </div>

            <div className="relative hidden md:block">
              <div className="mx-auto h-72 w-44 rounded-3xl border-4 border-white/20 bg-gradient-to-br from-white/10 to-white/5 p-2 shadow-2xl">
                <div className="h-full w-full overflow-hidden rounded-2xl bg-paper">
                  <div className="flex h-8 items-center gap-1.5 bg-wine/5 px-3">
                    <span className="h-1.5 w-1.5 rounded-full bg-wine/40" />
                    <span className="h-1.5 w-1.5 rounded-full bg-wine/30" />
                    <span className="h-1.5 w-1.5 rounded-full bg-wine/30" />
                  </div>
                  <div className="space-y-2 p-3">
                    <div className="h-2 w-3/4 rounded-full bg-wine/20" />
                    <div className="h-2 w-1/2 rounded-full bg-wine/15" />
                    <div className="mt-3 h-20 rounded-xl bg-gradient-to-br from-wine/20 to-orange/20" />
                    <div className="h-2 w-2/3 rounded-full bg-wine/15" />
                    <div className="h-2 w-1/3 rounded-full bg-wine/10" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
