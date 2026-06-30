import { useState } from "react";
import { Plus } from "lucide-react";
import { useReveal } from "../lib/hooks";

const faqs = [
  {
    q: "NotiqAI nima?",
    a: "NotiqAI — Najot Nur tomonidan ishlab chiqilgan platforma bo'lib, foydalanuvchilarning nutqi, ovozi va kuzatuvchanligini sun'iy intellekt yordamida tahlil qiladi va rivojlantiradi.",
  },
  {
    q: "Qanday qilib boshlash mumkin?",
    a: "Mobil ilovani App Store yoki Google Play'dan yuklab oling, telefon raqamingiz bilan ro'yxatdan o'ting — birinchi mashg'ulotni 5 daqiqada boshlaysiz.",
  },
  {
    q: "Bepul sinab ko'rsa bo'ladimi?",
    a: "Ha. Bepul tarifda 10 daqiqalik nutq tahlili, 5 ta audiokitob va boshlang'ich kurslar mavjud. Pro tarifga o'tish ixtiyoriy.",
  },
  {
    q: "AI qaysi tilda ishlaydi?",
    a: "Hozirda o'zbek, rus va ingliz tillarini qo'llab-quvvatlaydi. Talaffuz matnlari va audiokitoblar uchta tilda ham mavjud.",
  },
  {
    q: "Sertifikat qanday beriladi?",
    a: "Kurs yakunida avtomatik ravishda PDF sertifikat yaratiladi va ilovadan yuklab olinadi. Sertifikat rasmiy va raqamli imzoga ega.",
  },
  {
    q: "Kurator bilan ishlash qanday?",
    a: "Pro tarifda har bir o'quvchiga tajribali kurator biriktiriladi. Uy vazifalari, ovoz mashqlari va individual tavsiyalar.",
  },
];

export function FAQ() {
  const [open, setOpen] = useState<number | null>(0);
  const { ref, visible } = useReveal<HTMLDivElement>();
  return (
    <section id="faq" className="bg-paper py-20 md:py-28">
      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-wine">
              FAQ
            </span>
            <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
              Ko'p so'raladigan savollar
            </h2>
          </div>

          <div className="mx-auto mt-12 max-w-3xl divide-y divide-line overflow-hidden rounded-2xl border border-line bg-white">
            {faqs.map((f, i) => {
              const isOpen = open === i;
              return (
                <div
                  key={f.q}
                  style={{ animation: `fade-up 0.5s ${i * 0.05}s ease-out both` }}
                >
                  <button
                    className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left transition hover:bg-wine-50/50"
                    onClick={() => setOpen(isOpen ? null : i)}
                    aria-expanded={isOpen}
                  >
                    <span className="text-base font-bold">{f.q}</span>
                    <Plus
                      size={18}
                      className={`shrink-0 text-wine transition-transform duration-300 ${
                        isOpen ? "rotate-45" : ""
                      }`}
                      strokeWidth={2.5}
                    />
                  </button>
                  <div
                    className={`grid overflow-hidden px-6 transition-[grid-template-rows] duration-300 ${
                      isOpen ? "grid-rows-[1fr] pb-5" : "grid-rows-[0fr]"
                    }`}
                  >
                    <div className="min-h-0 text-sm leading-relaxed text-muted">
                      {f.a}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
