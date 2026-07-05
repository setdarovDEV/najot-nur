import type { ReactNode } from "react";
import { BRAND } from "../lib/config";
import { openDemo } from "../lib/device";
import { track, type TrackingEventName } from "../lib/tracking";

interface CTAButtonProps {
  id: string;
  event: TrackingEventName;
  children: ReactNode;
  variant?: "primary" | "secondary" | "inverse";
  size?: "md" | "lg";
  className?: string;
  meta?: Record<string, unknown>;
  /** "demo" opens the pronunciation demo modal; "link" navigates to app URL */
  action?: "demo" | "link";
}

const VARIANTS = {
  primary:
    "bg-gradient-to-br from-wine-600 to-wine-800 text-white shadow-cta hover:from-wine-500 hover:to-wine-700 hover:-translate-y-0.5",
  secondary:
    "bg-white text-wine-700 border-2 border-wine-100 shadow-card hover:border-wine-300 hover:-translate-y-0.5",
  inverse: "bg-white text-wine-800 shadow-lg hover:bg-wine-50 hover:-translate-y-0.5",
} as const;

const SIZES = {
  md: "px-6 py-3.5 text-sm",
  lg: "px-8 py-4 text-base",
} as const;

const BASE =
  "inline-flex min-h-12 items-center justify-center gap-2 rounded-2xl font-bold transition-all duration-200 active:translate-y-0 active:scale-[0.98]";

export default function CTAButton({
  id,
  event,
  children,
  variant = "primary",
  size = "lg",
  className = "",
  meta,
  action = "demo",
}: CTAButtonProps) {
  const cls = `${BASE} ${VARIANTS[variant]} ${SIZES[size]} ${className}`;

  if (action === "demo") {
    return (
      <button
        id={id}
        onClick={() => {
          track(event, { button_id: id, ...meta });
          openDemo();
        }}
        className={cls}
      >
        {children}
      </button>
    );
  }

  return (
    <a
      id={id}
      href={BRAND.links.app}
      onClick={() => track(event, { button_id: id, ...meta })}
      className={cls}
    >
      {children}
    </a>
  );
}
