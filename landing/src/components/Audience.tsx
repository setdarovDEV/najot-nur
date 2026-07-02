import { Briefcase, Clapperboard, GraduationCap, Presentation, TrendingUp } from "lucide-react";
import { useReveal } from "../lib/hooks";

const AUDIENCE = [
  { title: "Sotuv menejerlari", icon: TrendingUp },
  { title: "Rahbarlar va tadbirkorlar", icon: Briefcase },
  { title: "Talabalar", icon: GraduationCap },
  { title: "Kontent yaratuvchilar", icon: Clapperboard },
  { title: "Suhbat yoki prezentatsiyaga tayyorlanayotganlar", icon: Presentation },
];

export default function Audience() {
  const { ref, visible } = useReveal();

  return (
    <section className="py-14 sm:py-20">
      <div
        ref={ref}
        className={`reveal mx-auto max-w-6xl px-4 sm:px-6 ${visible ? "is-visible" : ""}`}
      >
        <div className="reveal-item text-center">
          <span className="rounded-full bg-wine-50 px-3.5 py-1.5 text-xs font-extrabold uppercase tracking-wider text-wine-700 ring-1 ring-wine-100">
            Auditoriya
          </span>
          <h2 className="mt-4 text-2xl font-extrabold tracking-tight text-ink sm:text-3xl">
            Bu kimlar uchun?
          </h2>
        </div>

        <div className="mt-10 flex flex-wrap justify-center gap-4">
          {AUDIENCE.map((item, i) => (
            <div
              key={item.title}
              className="reveal-item group flex items-center gap-3 rounded-2xl bg-white px-5 py-4 shadow-card ring-1 ring-transparent transition-all duration-300 hover:-translate-y-1.5 hover:shadow-soft hover:ring-wine-200"
              style={{ "--d": `${100 + i * 100}ms` } as React.CSSProperties}
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-wine-50 text-wine-700 transition-all duration-300 group-hover:scale-110 group-hover:bg-wine-700 group-hover:text-white">
                <item.icon className="h-5 w-5" />
              </div>
              <span className="text-sm font-bold text-ink">{item.title}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
