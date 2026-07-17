import { forwardRef, useLayoutEffect, useRef, useState, type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes, type TextareaHTMLAttributes } from "react";

/** The soft, fixed radial-gradient glows every screen sits on top of.
 * Pure CSS gradients — no filter/blur() — so it costs nothing to keep
 * mounted behind scrolling content. */
export function AmbientOrbs() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden>
      <div
        className="absolute -left-24 top-24 h-[340px] w-[340px] rounded-full opacity-70 dark:opacity-50"
        style={{
          background:
            "radial-gradient(circle, rgba(91,194,231,0.35) 0%, rgba(91,194,231,0) 85%)",
        }}
      />
      <div
        className="absolute -right-20 top-[38%] h-[380px] w-[380px] rounded-full opacity-70 dark:opacity-50"
        style={{
          background:
            "radial-gradient(circle, rgba(255,92,57,0.3) 0%, rgba(255,92,57,0) 85%)",
        }}
      />
      <div
        className="absolute bottom-0 left-[18%] h-[320px] w-[320px] rounded-full opacity-70 dark:opacity-50"
        style={{
          background:
            "radial-gradient(circle, rgba(138,21,56,0.22) 0%, rgba(138,21,56,0) 85%)",
        }}
      />
    </div>
  );
}

/** Fade + rise + settle entrance, staggered per item (55ms step). */
export function Reveal({
  children,
  index = 0,
  className = "",
}: {
  children: ReactNode;
  index?: number;
  className?: string;
}) {
  return (
    <div
      className={`animate-fade-rise ${className}`}
      style={{ animationDelay: `${Math.min(index, 12) * 55}ms` }}
    >
      {children}
    </div>
  );
}

export function GlassCard({
  children,
  className = "",
  as: As = "div",
  sub,
}: {
  children: ReactNode;
  className?: string;
  as?: "div" | "section" | "article";
  /** Sub-card tier (radius 24 instead of 28). */
  sub?: boolean;
}) {
  return (
    <As
      className={`border border-line bg-card ${sub ? "rounded-3xl" : "rounded-2xl"} ${className}`}
    >
      {children}
    </As>
  );
}

export function PrimaryButton({
  children,
  className = "",
  loading,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { loading?: boolean }) {
  return (
    <button
      {...rest}
      disabled={rest.disabled || loading}
      className={`btn-primary inline-flex items-center justify-center gap-2 px-5 py-2.5 text-sm font-bold disabled:cursor-not-allowed ${className}`}
    >
      {children}
    </button>
  );
}

export function SecondaryButton({
  children,
  className = "",
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      {...rest}
      className={`btn-secondary inline-flex items-center justify-center gap-2 px-5 py-2.5 text-sm font-semibold text-ink disabled:cursor-not-allowed disabled:opacity-60 ${className}`}
    >
      {children}
    </button>
  );
}

export const GlassInput = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function GlassInput({ className = "", ...rest }, ref) {
    return (
      <input
        ref={ref}
        {...rest}
        className={`glass-input w-full px-3.5 py-2.5 text-sm text-ink placeholder:text-muted disabled:opacity-60 ${className}`}
      />
    );
  }
);

export function GlassTextarea({
  className = "",
  ...rest
}: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...rest}
      className={`glass-input w-full px-3.5 py-2.5 text-sm text-ink placeholder:text-muted disabled:opacity-60 ${className}`}
    />
  );
}

export function GlassSelect({
  className = "",
  children,
  ...rest
}: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      {...rest}
      className={`glass-input w-full px-3.5 py-2.5 text-sm text-ink disabled:opacity-60 ${className}`}
    >
      {children}
    </select>
  );
}

export type PillTone = "success" | "danger" | "warning" | "neutral";

export function StatusPill({
  tone,
  children,
  className = "",
}: {
  tone: PillTone;
  children: ReactNode;
  className?: string;
}) {
  return (
    <span className={`status-pill status-pill-${tone} ${className}`}>{children}</span>
  );
}

export interface SegmentOption<T extends string> {
  value: T;
  label: ReactNode;
}

/** A pill track whose colored indicator morphs to the active option. */
export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  className = "",
}: {
  options: SegmentOption<T>[];
  value: T;
  onChange: (v: T) => void;
  className?: string;
}) {
  const trackRef = useRef<HTMLDivElement>(null);
  const btnRefs = useRef<Record<string, HTMLButtonElement | null>>({});
  const [indicator, setIndicator] = useState<{ left: number; width: number }>({
    left: 0,
    width: 0,
  });

  useLayoutEffect(() => {
    const track = trackRef.current;
    const btn = btnRefs.current[value];
    if (!track || !btn) return;
    const trackRect = track.getBoundingClientRect();
    const btnRect = btn.getBoundingClientRect();
    setIndicator({ left: btnRect.left - trackRect.left, width: btnRect.width });
  }, [value, options.length]);

  return (
    <div ref={trackRef} className={`segmented-track ${className}`}>
      <div
        className="segmented-indicator"
        style={{ left: indicator.left, width: indicator.width }}
      />
      {options.map((opt) => (
        <button
          key={opt.value}
          ref={(el) => {
            btnRefs.current[opt.value] = el;
          }}
          type="button"
          onClick={() => onChange(opt.value)}
          className={`segmented-btn px-4 py-1.5 text-sm font-semibold transition-colors ${
            value === opt.value ? "text-white" : "text-muted hover:text-ink"
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
