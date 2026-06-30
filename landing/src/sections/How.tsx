import { Mic, FileText, BarChart3 } from "lucide-react";
import { useReveal } from "../lib/hooks";

const steps = [
  {
    n: "01",
    icon: Mic,
    title: "Yozib oling",
    text: "2 daqiqalik nutq yoki berilgan matnni ovozda o'qing. Mobil ilova yoki web orqali.",
  },
  {
    n: "02",
    icon: FileText,
    title: "AI tahlil qiladi",
    text: "Sun'iy intellekt har bir so'zni, pauzani, emotsiyani va talaffuzni aniqlik bilan tahlil qiladi.",
  },
  {
    n: "03",
    icon: BarChart3,
    title: "Natijani oling",
    text: "Batafsil hisobot, aniqlik foizi, xato so'zlar va kurator tavsiyalari — hammasi bitta joyda.",
  },
];

export function How() {
  const { ref, visible } = useReveal<HTMLDivElement>();
  return (
    <section id="how" className="relative overflow-hidden bg-white py-20 md:py-28">
      <div
        aria-hidden
        className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-wine/20 to-transparent"
      />
      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-wine">
              Qanday ishlaydi
            </span>
            <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
              3 ta oddiy qadamda natija
            </h2>
          </div>

          <div className="mt-14 grid gap-6 md:grid-cols-3">
            {steps.map((s, i) => (
              <div
                key={s.n}
                className="group relative overflow-hidden rounded-2xl border border-line bg-paper p-7 transition hover:-translate-y-1 hover:border-wine/30 hover:shadow-xl hover:shadow-wine/5"
                style={{
                  animation: `fade-up 0.7s ${i * 0.12}s ease-out both`,
                }}
              >
                <div className="flex items-center justify-between">
                  <span className="text-5xl font-black text-wine/15 transition group-hover:text-wine/30 group-hover:scale-110">
                    {s.n}
                  </span>
                  <div className="grid h-11 w-11 place-items-center rounded-xl bg-wine text-white transition group-hover:rotate-12 group-hover:scale-110">
                    <s.icon size={18} strokeWidth={1.75} />
                  </div>
                </div>
                <h3 className="mt-6 text-xl font-extrabold">{s.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted">{s.text}</p>

                {i < steps.length - 1 && (
                  <div
                    aria-hidden
                    className="absolute right-[-24px] top-1/2 hidden h-px w-12 bg-gradient-to-r from-wine/20 to-transparent md:block"
                  />
                )}
                <div
                  aria-hidden
                  className="absolute -bottom-20 -right-20 h-40 w-40 rounded-full bg-wine/0 transition group-hover:bg-wine/5"
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
