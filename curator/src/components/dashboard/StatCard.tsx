import type { LucideIcon } from "lucide-react";
import { ArrowUpRight, ArrowDownRight } from "lucide-react";
import type { ReactNode } from "react";

export type StatTone = "wine" | "orange" | "sky" | "ink";

const TONE_BG: Record<StatTone, string> = {
  wine: "bg-wine/10 text-wine",
  orange: "bg-orange/10 text-orange",
  sky: "bg-skyblue/15 text-skyblue",
  ink: "bg-ink/10 text-ink",
};

const TONE_GRADIENT: Record<StatTone, string> = {
  wine: "from-wine to-wine-dark",
  orange: "from-orange to-wine",
  sky: "from-skyblue to-wine",
  ink: "from-ink to-wine-deep",
};

export function StatCard({
  label,
  value,
  icon: Icon,
  tone = "wine",
  delta,
  hint,
  gradient = false,
  loading = false,
  footer,
}: {
  label: string;
  value: number | string | undefined;
  icon: LucideIcon;
  tone?: StatTone;
  delta?: { value: number; suffix?: string };
  hint?: string;
  gradient?: boolean;
  loading?: boolean;
  footer?: ReactNode;
}) {
  const positive = delta && delta.value >= 0;

  return (
    <div
      className={`group relative overflow-hidden rounded-2xl border border-line bg-card p-5 transition hover:border-wine/30 hover:shadow-lg hover:shadow-wine/5 ${
        gradient ? `bg-gradient-to-br ${TONE_GRADIENT[tone]} text-white border-transparent` : ""
      }`}
    >
      <div className="flex items-start justify-between">
        <div
          className={`grid h-11 w-11 place-items-center rounded-xl ${
            gradient ? "bg-white/15 text-white" : TONE_BG[tone]
          }`}
        >
          <Icon size={20} strokeWidth={1.75} />
        </div>
        {delta && (
          <span
            className={`inline-flex items-center gap-0.5 rounded-full px-2 py-0.5 text-[11px] font-bold ${
              gradient
                ? "bg-white/20 text-white"
                : positive
                  ? "bg-green-100 text-green-700"
                  : "bg-red-100 text-red-600"
            }`}
          >
            {positive ? (
              <ArrowUpRight size={11} strokeWidth={2.5} />
            ) : (
              <ArrowDownRight size={11} strokeWidth={2.5} />
            )}
            {Math.abs(delta.value)}
            {delta.suffix ?? "%"}
          </span>
        )}
      </div>

      <div className="mt-4">
        <div
          className={`text-3xl font-extrabold tracking-tight ${gradient ? "text-white" : "text-ink"}`}
        >
          {loading ? (
            <span className="inline-block h-8 w-16 animate-pulse rounded-md bg-line/60" />
          ) : value === undefined || value === null ? (
            "0"
          ) : (
            value
          )}
        </div>
        <div
          className={`mt-1 text-sm font-semibold ${gradient ? "text-white/85" : "text-ink"}`}
        >
          {label}
        </div>
        {hint && (
          <div
            className={`mt-1 text-xs ${gradient ? "text-white/65" : "text-muted"}`}
          >
            {hint}
          </div>
        )}
      </div>

      {footer && (
        <div
          className={`mt-4 border-t pt-3 text-xs ${
            gradient
              ? "border-white/15 text-white/80"
              : "border-line text-muted"
          }`}
        >
          {footer}
        </div>
      )}
    </div>
  );
}
