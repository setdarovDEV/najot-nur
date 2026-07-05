import { Mic } from "lucide-react";
import { openDemo } from "../lib/device";
import { useScrolledPast } from "../lib/hooks";
import { track } from "../lib/tracking";

/** Mobile-only sticky CTA — appears after the hero is scrolled. */
export default function StickyCTA() {
  const show = useScrolledPast(480);

  if (!show) return null;

  return (
    <div className="animate-slide-up fixed inset-x-0 bottom-0 z-50 border-t border-wine-100 bg-white/95 p-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))] shadow-[0_-8px_30px_rgba(63,8,26,0.12)] backdrop-blur-md md:hidden">
      <div className="flex items-center justify-between gap-3">
        <div className="pl-1 leading-tight">
          <span className="text-[10px] font-extrabold uppercase tracking-wide text-emerald-600">
            Mutlaqo bepul
          </span>
          <div className="text-sm font-extrabold text-ink">5 daqiqada AI tahlil</div>
        </div>
        <button
          id="sticky_cta"
          onClick={() => {
            track("main_cta_click", { button_id: "sticky_cta", placement: "sticky" });
            openDemo();
          }}
          className="btn-shimmer flex min-h-12 items-center gap-2 rounded-2xl bg-gradient-to-br from-wine-600 to-wine-800 px-5 py-3 text-sm font-bold text-white shadow-cta active:scale-[0.98]"
        >
          <Mic className="h-4 w-4" />
          Bepul testni boshlash
        </button>
      </div>
    </div>
  );
}
