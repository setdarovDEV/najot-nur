import { Target, Compass, Sparkles, Award, Users, MapPin, Calendar } from "lucide-react";
import { BRAND } from "../lib/config";
import { useReveal, useCountUp } from "../lib/hooks";

const stats = [
  { icon: Users, value: 5300, suffix: "+", label: "Bitiruvchi" },
  { icon: Award, value: 24, suffix: "", label: "Kurs va intensiv" },
  { icon: MapPin, value: 12, suffix: "+", label: "Filial shahar" },
  { icon: Calendar, value: 8, suffix: " yil", label: "Tajriba" },
];

export function About() {
  const { ref, visible } = useReveal<HTMLDivElement>();

  return (
    <section id="about" className="relative overflow-hidden bg-white py-20 md:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute -right-32 top-20 h-72 w-72 animate-blob rounded-full bg-wine/5 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -left-20 bottom-10 h-64 w-64 animate-blob rounded-full bg-orange/10 blur-3xl"
        style={{ animationDelay: "3s" }}
      />

      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="grid items-start gap-12 lg:grid-cols-2">
            <div>
              <span className="inline-flex items-center gap-1.5 rounded-full bg-wine-50 px-3 py-1 text-xs font-bold text-wine">
                <Sparkles size={12} className="animate-wiggle" />
                Biz haqimizda
              </span>
              <h2 className="mt-4 text-4xl font-extrabold md:text-5xl">
                <span className="text-gradient-wine">Najot Nur</span> — O'zbekistondagi
                eng yirik notiqlik markazi
              </h2>
              <p className="mt-5 text-lg leading-relaxed text-muted">
                {BRAND.about.intro}
              </p>

              <div className="mt-6 flex flex-wrap items-center gap-3 text-sm">
                <span className="inline-flex items-center gap-2 rounded-full border border-line bg-paper px-3 py-1.5 font-semibold text-ink">
                  <MapPin size={13} className="text-wine" />
                  Toshkent · 12+ filial
                </span>
                <span className="inline-flex items-center gap-2 rounded-full border border-line bg-paper px-3 py-1.5 font-semibold text-ink">
                  <Calendar size={13} className="text-wine" />
                  2018-yildan buyon
                </span>
                <span className="inline-flex items-center gap-2 rounded-full border border-line bg-paper px-3 py-1.5 font-semibold text-ink">
                  <Users size={13} className="text-wine" />
                  200K+ ijtimoiy tarmoq
                </span>
              </div>

              <div className="mt-8">
                <a
                  href={BRAND.parentUrl}
                  target="_blank"
                  rel="noreferrer noopener"
                  className="group inline-flex items-center gap-2 rounded-2xl border border-wine/20 bg-wine-50 px-5 py-3 text-sm font-bold text-wine transition hover:border-wine/40 hover:bg-wine hover:text-white"
                >
                  najotnur.uz saytiga o'tish
                  <Compass size={15} className="transition group-hover:rotate-45" />
                </a>
              </div>
            </div>

            <div className="relative">
              <div
                aria-hidden
                className="absolute -inset-4 rounded-3xl bg-gradient-to-br from-wine/5 via-orange/5 to-skyblue/5"
              />
              <div className="relative rounded-3xl border border-line bg-paper p-7 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-xl bg-wine text-white">
                    <Target size={18} />
                  </div>
                  <div>
                    <div className="text-xs font-bold uppercase tracking-wider text-wine">
                      BIZNING MAQSAD
                    </div>
                    <div className="text-sm font-semibold text-ink">
                      O'zbekistondagi notiqlik madaniyatini yangi bosqichga olib chiqish
                    </div>
                  </div>
                </div>
                <p className="mt-4 text-sm leading-relaxed text-muted">
                  {BRAND.about.mission}
                </p>

                <div className="mt-6 space-y-3">
                  {BRAND.about.pillars.map((p, i) => (
                    <PillarItem key={p.title} index={i} title={p.title} text={p.text} />
                  ))}
                </div>
              </div>
            </div>
          </div>

          <div className="mt-16 grid gap-4 md:grid-cols-4">
            {stats.map((s, i) => (
              <StatCard key={s.label} {...s} delay={i * 100} startVisible={visible} />
            ))}
          </div>

          <div className="mt-14 rounded-3xl border border-line bg-gradient-to-br from-wine-50/60 via-white to-orange-50/50 p-7 md:p-9">
            <div className="mb-6 flex items-center gap-3">
              <div className="grid h-10 w-10 place-items-center rounded-xl bg-orange text-white">
                <Calendar size={18} />
              </div>
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-orange">
                  Tarix
                </div>
                <div className="text-base font-extrabold text-ink">
                  8 yil davomida o'sish
                </div>
              </div>
            </div>
            <ol className="relative space-y-5 border-l-2 border-wine/15 pl-6">
              {BRAND.about.milestones.map((m, i) => (
                <MilestoneItem key={m.year} year={m.year} text={m.text} index={i} />
              ))}
            </ol>
          </div>
        </div>
      </div>
    </section>
  );
}

function PillarItem({ index, title, text }: { index: number; title: string; text: string }) {
  return (
    <div
      className="group flex items-start gap-3 rounded-xl border border-line bg-white p-4 transition hover:border-wine/20 hover:shadow-md hover:shadow-wine/5"
      style={{ animation: `fade-up 0.6s ${index * 0.1}s ease-out both` }}
    >
      <div className="mt-0.5 grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-wine-50 text-xs font-black text-wine transition group-hover:bg-wine group-hover:text-white">
        0{index + 1}
      </div>
      <div>
        <div className="text-sm font-extrabold text-ink">{title}</div>
        <div className="mt-0.5 text-xs leading-relaxed text-muted">{text}</div>
      </div>
    </div>
  );
}

function StatCard({
  icon: Icon,
  value,
  suffix,
  label,
  delay,
  startVisible,
}: {
  icon: typeof Users;
  value: number;
  suffix: string;
  label: string;
  delay: number;
  startVisible: boolean;
}) {
  const count = useCountUp(value, 1600 + delay, startVisible);
  return (
    <div
      className="group relative overflow-hidden rounded-2xl border border-line bg-white p-5 transition hover:-translate-y-1 hover:border-wine/30 hover:shadow-xl hover:shadow-wine/5"
      style={{
        animation: `fade-up 0.7s ${delay}ms ease-out both`,
      }}
    >
      <div className="flex items-center justify-between">
        <div className="grid h-10 w-10 place-items-center rounded-xl bg-wine/10 text-wine transition group-hover:scale-110 group-hover:bg-wine group-hover:text-white">
          <Icon size={18} />
        </div>
        <div
          aria-hidden
          className="absolute -bottom-12 -right-12 h-32 w-32 rounded-full bg-wine/0 transition group-hover:bg-wine/5"
        />
      </div>
      <div className="mt-4 text-3xl font-extrabold tracking-tight text-ink">
        {count.toLocaleString("uz-UZ")}
        <span className="text-wine">{suffix}</span>
      </div>
      <div className="mt-1 text-xs font-semibold uppercase tracking-wider text-muted">
        {label}
      </div>
    </div>
  );
}

function MilestoneItem({ year, text, index }: { year: string; text: string; index: number }) {
  return (
    <li
      className="relative"
      style={{ animation: `fade-up 0.6s ${index * 0.08}s ease-out both` }}
    >
      <span className="absolute -left-[33px] top-1 grid h-6 w-6 place-items-center rounded-full bg-wine text-[10px] font-black text-white shadow-md shadow-wine/30">
        {index + 1}
      </span>
      <div className="flex flex-wrap items-baseline gap-2">
        <span className="text-lg font-black text-wine">{year}</span>
        <span className="text-sm leading-relaxed text-ink/80">{text}</span>
      </div>
    </li>
  );
}
