import { useId } from "react";

export interface RingSlice {
  label: string;
  value: number;
  color: string;
}

export function RingChart({
  slices,
  size = 140,
  thickness = 16,
  centerLabel,
  centerValue,
}: {
  slices: RingSlice[];
  size?: number;
  thickness?: number;
  centerLabel?: string;
  centerValue?: string;
}) {
  const total = slices.reduce((s, x) => s + x.value, 0) || 1;
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const id = useId();

  let offset = 0;

  return (
    <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-center sm:gap-6">
      <div
        className="relative shrink-0"
        style={{ width: size, height: size }}
      >
        <svg
          width={size}
          height={size}
          viewBox={`0 0 ${size} ${size}`}
          className="-rotate-90"
        >
          <circle
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            stroke="#f3edef"
            strokeWidth={thickness}
          />
          {slices.map((s, i) => {
            if (s.value === 0) return null;
            const frac = s.value / total;
            const dash = c * frac;
            const seg = (
              <circle
                key={`${id}-${i}`}
                cx={size / 2}
                cy={size / 2}
                r={r}
                fill="none"
                stroke={s.color}
                strokeWidth={thickness}
                strokeDasharray={`${dash} ${c - dash}`}
                strokeDashoffset={-offset}
                strokeLinecap="round"
              />
            );
            offset += dash;
            return seg;
          })}
        </svg>
        <div className="absolute inset-0 grid place-items-center text-center">
          <div>
            <div className="text-2xl font-extrabold text-ink">
              {centerValue ?? total}
            </div>
            {centerLabel && (
              <div className="mt-0.5 text-xs font-semibold text-muted">
                {centerLabel}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="flex-1 space-y-2">
        {slices.map((s, i) => {
          const pct = total ? Math.round((s.value / total) * 100) : 0;
          return (
            <div
              key={`${id}-l-${i}`}
              className="flex items-center justify-between gap-3 text-sm"
            >
              <div className="flex min-w-0 items-center gap-2">
                <span
                  className="h-2.5 w-2.5 shrink-0 rounded-full"
                  style={{ backgroundColor: s.color }}
                />
                <span className="truncate text-muted">{s.label}</span>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <span className="font-bold text-ink">{s.value}</span>
                <span className="text-xs text-muted">{pct}%</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
