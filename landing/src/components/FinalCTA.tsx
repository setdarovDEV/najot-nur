import { Mic } from "lucide-react";
import CTAButton from "./CTAButton";
import { useReveal } from "../lib/hooks";

export default function FinalCTA() {
  const { ref, visible } = useReveal();

  return (
    <section id="boshlash" className="px-4 py-14 sm:px-6 sm:py-20">
      <div
        ref={ref}
        className={`reveal bg-gradient-animated relative mx-auto max-w-4xl overflow-hidden rounded-[2.5rem] px-6 py-14 text-center text-white shadow-cta sm:px-12 ${visible ? "is-visible" : ""}`}
      >
        {/* Animated glow orbs */}
        <div className="animate-blob pointer-events-none absolute -top-16 left-1/2 h-48 w-96 -translate-x-1/2 rounded-full bg-wine-400/40 blur-3xl" />
        <div className="animate-blob-reverse pointer-events-none absolute -bottom-20 right-0 h-48 w-48 rounded-full bg-brand-orange/25 blur-3xl" />
        <div className="animate-blob pointer-events-none absolute -left-10 top-1/2 h-40 w-40 rounded-full bg-brand-sky/20 blur-3xl [animation-delay:-9s]" />

        {/* Shield watermark */}
        <img
          src="/logo-nn-white.png"
          alt=""
          aria-hidden
          className="pointer-events-none absolute -right-8 -top-10 h-56 w-auto rotate-12 opacity-[0.07]"
        />

        {/* Pulsing mic emblem */}
        <div className="reveal-item relative mx-auto mb-6 h-16 w-16">
          <span className="animate-pulse-ring absolute inset-0 rounded-full bg-white/40" />
          <span className="animate-pulse-ring absolute inset-0 rounded-full bg-white/25 [animation-delay:0.9s]" />
          <div className="relative flex h-16 w-16 items-center justify-center rounded-full bg-white/15 ring-1 ring-white/30 backdrop-blur-sm">
            <Mic className="h-7 w-7" />
          </div>
        </div>

        <h2 className="reveal-item relative text-2xl font-extrabold tracking-tight sm:text-4xl" style={{ "--d": "120ms" } as React.CSSProperties}>
          Nutqingiz qanday eshitilishini bilmoqchimisiz?
        </h2>
        <p className="reveal-item relative mx-auto mt-4 max-w-md text-base leading-relaxed text-white/80" style={{ "--d": "240ms" } as React.CSSProperties}>
          Telefoningizdan 2 daqiqa gapiring va AI tahlilini oling.
        </p>

        <div className="reveal-item relative mt-8" style={{ "--d": "360ms" } as React.CSSProperties}>
          <CTAButton
            id="final_cta"
            event="main_cta_click"
            variant="inverse"
            className="btn-shimmer"
            meta={{ placement: "final" }}
          >
            <Mic className="h-5 w-5" />
            Bepul testni boshlash
          </CTAButton>
        </div>

        <p className="reveal-item relative mt-5 text-xs font-semibold text-white/60" style={{ "--d": "480ms" } as React.CSSProperties}>
          Ro‘yxatdan o‘tish yo‘q · 5 daqiqada natija · Mutlaqo bepul
        </p>
      </div>
    </section>
  );
}
