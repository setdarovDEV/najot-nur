import { Smartphone, Download, ScanLine } from "lucide-react";
import { BRAND } from "../lib/config";
import { useReveal } from "../lib/hooks";
import { QRPlaceholder } from "../components/QRPlaceholder";

export function QRBanner() {
  const { ref, visible } = useReveal<HTMLDivElement>();

  return (
    <section id="app" className="relative overflow-hidden bg-white py-20 md:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute -right-20 top-0 h-96 w-96 animate-blob rounded-full bg-orange/10 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -left-20 bottom-0 h-96 w-96 animate-blob rounded-full bg-skyblue/15 blur-3xl"
        style={{ animationDelay: "2s" }}
      />

      <div className="container-x">
        <div
          ref={ref}
          className={`reveal ${visible ? "is-visible" : ""} relative overflow-hidden rounded-[2.5rem] border border-line bg-gradient-to-br from-wine via-wine-dark to-wine-deep p-8 text-white md:p-14`}
        >
          <div
            aria-hidden
            className="absolute -right-32 -top-32 h-80 w-80 rounded-full bg-orange/30 blur-3xl"
          />
          <div
            aria-hidden
            className="absolute -bottom-32 -left-32 h-80 w-80 rounded-full bg-skyblue/30 blur-3xl"
          />
          <div
            aria-hidden
            className="absolute inset-0 opacity-[0.07]"
            style={{
              backgroundImage:
                "radial-gradient(circle, rgba(255,255,255,0.4) 1px, transparent 1px)",
              backgroundSize: "22px 22px",
            }}
          />

          <div className="relative grid items-center gap-10 md:grid-cols-2">
            <div>
              <span className="inline-flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-1 text-xs font-bold uppercase tracking-wider backdrop-blur">
                <Smartphone size={12} className="animate-wiggle" />
                Mobil ilova
              </span>
              <h2 className="mt-4 text-3xl font-extrabold leading-tight md:text-5xl">
                Telefoningizga{" "}
                <span className="bg-gradient-to-r from-orange via-skyblue to-white bg-clip-text text-transparent">
                  NotiqAI
                </span>{" "}
                ni yuklab oling
              </h2>
              <p className="mt-4 max-w-md text-base text-white/85">
                QR kodni skaner qiling va iOS yoki Android uchun maxsus tayyorlangan
                ilovamizni o'rnating. Hozircha demo-versiya — tez orada rasmiy reliz.
              </p>

              <div className="mt-6 flex flex-wrap items-center gap-3 text-sm">
                <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 font-semibold backdrop-blur">
                  <ScanLine size={13} />
                  QR orqali yuklab oling
                </div>
                <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 font-semibold backdrop-blur">
                  <Download size={13} />
                  Tez orada App Store & Play Market
                </div>
              </div>

              <div className="mt-6 flex items-center gap-2 text-xs text-white/70">
                <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-orange" />
                Demo-versiya · rasmiy havola tez orada
              </div>
            </div>

            <div className="flex flex-col items-center gap-5 md:flex-row md:justify-end md:items-stretch">
              <div
                className="reveal-scale is-visible"
                style={{ animation: "fade-up 0.8s 0.1s ease-out both" }}
              >
                <QRPlaceholder
                  label="Google Play"
                  store="play"
                  href={BRAND.links.playMarket}
                />
              </div>
              <div
                className="reveal-scale is-visible"
                style={{ animation: "fade-up 0.8s 0.25s ease-out both" }}
              >
                <QRPlaceholder
                  label="App Store"
                  store="ios"
                  href={BRAND.links.appStore}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
