import { Check, Sparkles } from "lucide-react";
import { BRAND } from "../lib/config";

const plans = [
  {
    name: "Bepul",
    price: "0",
    suffix: "UZS / oy",
    desc: "Boshlang'ich tushuncha uchun",
    features: [
      "10 daqiqalik nutq tahlili",
      "5 ta audiokitob (bepul)",
      "2 ta kuzatuvchanlik testi",
      "1 ta video kurs",
    ],
    cta: "Bepul boshlash",
    href: "#cta",
    highlight: false,
  },
  {
    name: "Pro",
    price: "299 000",
    suffix: "UZS / oy",
    desc: "Jiddiy o'sish uchun",
    features: [
      "Cheksiz nutq tahlili",
      "50+ audiokitob",
      "Barcha video kurslar",
      "1-1 kurator bilan mashg'ulot",
      "Sertifikat",
      "Prioritet qo'llab-quvvatlash",
    ],
    cta: "Pro tarifga o'tish",
    href: "#cta",
    highlight: true,
    badge: "Mashhur",
  },
  {
    name: "Jamoa",
    price: "Aloqaga",
    suffix: "",
    desc: "Korporativ mijozlar uchun",
    features: [
      "Pro'dagi hammasi",
      "Maxsus kurator",
      "Brend hisoboti",
      "API integratsiya",
      "Maxsus kurs yaratish",
    ],
    cta: "Bog'lanish",
    href: `mailto:${BRAND.contact.email}`,
    highlight: false,
  },
];

export function Pricing() {
  return (
    <section id="pricing" className="bg-paper py-20 md:py-28">
      <div className="container-x">
        <div className="mx-auto max-w-2xl text-center">
          <span className="text-xs font-bold uppercase tracking-wider text-wine">
            Narxlar
          </span>
          <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
            Sizga mos tarifni tanlang
          </h2>
          <p className="mt-4 text-lg text-muted">
            Bir oy bepul sinab ko'ring. Hech qanday yashirin to'lov yo'q.
          </p>
        </div>

        <div className="mt-14 grid gap-6 lg:grid-cols-3">
          {plans.map((p) => (
            <div
              key={p.name}
              className={`relative flex flex-col rounded-3xl border p-8 transition ${
                p.highlight
                  ? "border-wine bg-gradient-to-br from-wine to-wine-dark text-white shadow-2xl shadow-wine/30 lg:scale-[1.02]"
                  : "border-line bg-white"
              }`}
            >
              {p.badge && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <span className="inline-flex items-center gap-1 rounded-full bg-orange px-3 py-1 text-[11px] font-black uppercase tracking-wider text-white shadow-lg shadow-orange/30">
                    <Sparkles size={11} />
                    {p.badge}
                  </span>
                </div>
              )}
              <div>
                <div className={`text-sm font-bold uppercase tracking-wider ${p.highlight ? "text-white/80" : "text-wine"}`}>
                  {p.name}
                </div>
                <div className="mt-3 flex items-baseline gap-1.5">
                  <span className="text-4xl font-extrabold tracking-tight md:text-5xl">
                    {p.price}
                  </span>
                  {p.suffix && (
                    <span className={`text-sm font-semibold ${p.highlight ? "text-white/70" : "text-muted"}`}>
                      {p.suffix}
                    </span>
                  )}
                </div>
                <p className={`mt-2 text-sm ${p.highlight ? "text-white/80" : "text-muted"}`}>
                  {p.desc}
                </p>
              </div>

              <ul className="mt-6 flex-1 space-y-3">
                {p.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <span
                      className={`mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full ${
                        p.highlight ? "bg-white/20 text-white" : "bg-wine/10 text-wine"
                      }`}
                    >
                      <Check size={12} strokeWidth={3} />
                    </span>
                    <span className="text-sm">{f}</span>
                  </li>
                ))}
              </ul>

              <a
                href={p.href}
                className={`mt-8 inline-flex items-center justify-center rounded-2xl px-6 py-3 text-sm font-bold transition ${
                  p.highlight
                    ? "bg-white text-wine hover:bg-paper"
                    : "bg-wine text-white hover:bg-wine-dark"
                }`}
              >
                {p.cta}
              </a>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
