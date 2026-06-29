export interface BarDatum {
  label: string;
  value: number;
  color?: string;
}

export function BarChart({
  data,
  height = 160,
  max,
  unit = "",
  emptyText = "Ma'lumot yo'q",
}: {
  data: BarDatum[];
  height?: number;
  max?: number;
  unit?: string;
  emptyText?: string;
}) {
  const ceiling = max ?? Math.max(1, ...data.map((d) => d.value));
  const total = data.reduce((s, x) => s + x.value, 0);

  if (total === 0) {
    return (
      <div
        className="grid place-items-center rounded-xl border border-dashed border-line text-sm text-muted"
        style={{ height }}
      >
        {emptyText}
      </div>
    );
  }

  return (
    <div className="space-y-3" style={{ minHeight: height }}>
      {data.map((d) => {
        const pct = (d.value / ceiling) * 100;
        const color = d.color ?? "#8A1538";
        return (
          <div key={d.label} className="text-sm">
            <div className="mb-1 flex items-center justify-between">
              <span className="font-semibold text-ink">{d.label}</span>
              <span className="font-bold text-ink">
                {d.value}
                {unit}
              </span>
            </div>
            <div className="h-2.5 overflow-hidden rounded-full bg-line/60">
              <div
                className="h-full rounded-full transition-all duration-700 ease-out"
                style={{
                  width: `${pct}%`,
                  backgroundColor: color,
                }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}
