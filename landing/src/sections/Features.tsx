import { Mic, Headphones, Eye, ClipboardCheck, Award, Headphones as Pod, type LucideIcon } from "lucide-react";
import { useReveal } from "../lib/hooks";

const features: { icon: LucideIcon; title: string; text: string; tone: string }[] = [
  {
    icon: Mic,
    title: "Nutq tahlili",
    text: "2 daqiqalik nutqingizni yuklang — AI parazit so'zlar, pauzalar va ma'no yetkazilishini aniqlaydi.",
    tone: "bg-wine/10 text-wine",
  },
  {
    icon: Headphones,
    title: "Ovoz tekshirish",
    text: "Berilgan matnni o'qing — xato tovush va so'zlaringiz qizil rangda belgilanadi, umumiy ball beriladi.",
    tone: "bg-skyblue/15 text-skyblue",
  },
  {
    icon: Eye,
    title: "Kuzatuvchanlik",
    text: "10 ta video va rasm asosida tana tili, emotsiya va diqqat testlari — psixologik tayyorgarlik.",
    tone: "bg-orange/10 text-orange",
  },
  {
    icon: ClipboardCheck,
    title: "Uy vazifalari",
    text: "Har dars yakunida topshiriqlar — kurator tomonidan batafsil tekshiriladi va ball qo'yiladi.",
    tone: "bg-wine/10 text-wine",
  },
  {
    icon: Award,
    title: "Sertifikat",
    text: "Kursni tugatganlarga rasmiy PDF sertifikat beriladi — professional portfolioga qo'shing.",
    tone: "bg-orange/10 text-orange",
  },
  {
    icon: Pod,
    title: "Audiokitoblar",
    text: "Ekspert ovozi bilan yozilgan 50+ audiokitob — eshitib, tinglab, talaffuzni takomillashtiring.",
    tone: "bg-skyblue/15 text-skyblue",
  },
];

export function Features() {
  const { ref, visible } = useReveal<HTMLDivElement>();
  return (
    <section id="features" className="bg-paper py-20 md:py-28">
      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-wine">
              Imkoniyatlar
            </span>
            <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
              Bir platformada — to'liq notiqlik ekotizimi
            </h2>
            <p className="mt-4 text-lg text-muted">
              Sun'iy intellekt va tajribali kuratorlar — sizning natijangiz uchun birga ishlaydi.
            </p>
          </div>

          <div className="mt-14 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
            {features.map((f, i) => (
              <div
                key={f.title}
                className="group relative overflow-hidden rounded-2xl border border-line bg-white p-7 transition hover:-translate-y-1 hover:border-wine/30 hover:shadow-xl hover:shadow-wine/5"
                style={{
                  animation: `fade-up 0.7s ${i * 0.08}s ease-out both`,
                }}
              >
                <div
                  className={`grid h-12 w-12 place-items-center rounded-xl ${f.tone} transition group-hover:scale-110 group-hover:rotate-3`}
                >
                  <f.icon size={22} strokeWidth={1.75} />
                </div>
                <h3 className="mt-5 text-lg font-extrabold">{f.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted">{f.text}</p>
                <div
                  aria-hidden
                  className="absolute -bottom-12 -right-12 h-32 w-32 rounded-full bg-wine/0 transition group-hover:bg-wine/5"
                />
                <div
                  aria-hidden
                  className="absolute left-0 top-0 h-1 w-0 bg-gradient-to-r from-wine to-orange transition-all duration-500 group-hover:w-full"
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
