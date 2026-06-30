type QRPlaceholderProps = {
  label: string;
  store: "play" | "ios";
  href: string;
  size?: number;
};

function makePattern(seed: number, size: number) {
  const cells: { x: number; y: number }[] = [];
  let s = seed;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      s = (s * 9301 + 49297) % 233280;
      if (s / 233280 > 0.5) cells.push({ x, y });
    }
  }
  return cells;
}

function QRCode({ seed, size = 21 }: { seed: number; size?: number }) {
  const cells = makePattern(seed, size);
  const cellSize = 100 / size;
  const finder = (cx: number, cy: number) => (
    <g>
      <rect
        x={`${cx * cellSize}%`}
        y={`${cy * cellSize}%`}
        width={`${cellSize * 7}%`}
        height={`${cellSize * 7}%`}
        fill="#14181F"
      />
      <rect
        x={`${(cx + 1) * cellSize}%`}
        y={`${(cy + 1) * cellSize}%`}
        width={`${cellSize * 5}%`}
        height={`${cellSize * 5}%`}
        fill="#FAF7F4"
      />
      <rect
        x={`${(cx + 2) * cellSize}%`}
        y={`${(cy + 2) * cellSize}%`}
        width={`${cellSize * 3}%`}
        height={`${cellSize * 3}%`}
        fill="#14181F"
      />
    </g>
  );

  return (
    <svg
      viewBox="0 0 100 100"
      xmlns="http://www.w3.org/2000/svg"
      className="h-full w-full"
      shapeRendering="crispEdges"
      aria-label="QR kod"
    >
      <rect width="100" height="100" fill="#FAF7F4" />
      {cells.map((c, i) => (
        <rect
          key={i}
          x={`${c.x * cellSize}%`}
          y={`${c.y * cellSize}%`}
          width={`${cellSize}%`}
          height={`${cellSize}%`}
          fill="#14181F"
        />
      ))}
      {finder(0, 0)}
      {finder(size - 7, 0)}
      {finder(0, size - 7)}
    </svg>
  );
}

export function QRPlaceholder({ label, store, href, size = 160 }: QRPlaceholderProps) {
  const seed = store === "play" ? 7331 : 9133;
  const accent = store === "play" ? "from-emerald-500 to-emerald-700" : "from-slate-700 to-slate-900";
  const Icon = store === "play"
    ? (
      <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden>
        <path d="M3.609 1.814 13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893 2.302 2.302-10.937 6.333 8.635-8.635zm3.787-3.787 2.554 1.479a1 1 0 0 1 0 1.736l-2.554 1.479-2.717-2.717 2.717-2.977zM5.864 2.658 16.8 9.005l-2.302 2.302L5.864 2.658z" />
      </svg>
    )
    : (
      <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden>
        <path d="M17.05 20.28c-.98.95-2.05.86-3.08.4-1.09-.47-2.09-.5-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
      </svg>
    );

  return (
    <a
      href={href}
      target={href === "#" ? undefined : "_blank"}
      rel="noreferrer noopener"
      className="group flex w-full max-w-[260px] flex-col items-center gap-3 rounded-3xl border border-line bg-white p-5 transition hover:-translate-y-1 hover:border-wine/30 hover:shadow-xl hover:shadow-wine/10"
    >
      <div className="relative">
        <div
          aria-hidden
          className={`absolute -inset-1 rounded-2xl bg-gradient-to-br ${accent} opacity-0 blur-md transition group-hover:opacity-40`}
        />
        <div
          className="relative rounded-2xl border-2 border-ink/90 bg-paper p-2.5 transition group-hover:scale-[1.02]"
          style={{ width: size, height: size }}
        >
          <QRCode seed={seed} />
        </div>
        <div
          aria-hidden
          className="pointer-events-none absolute -inset-1 rounded-2xl border border-wine/30 opacity-0 transition group-hover:opacity-100"
        />
      </div>
      <div className="text-center">
        <div className="flex items-center justify-center gap-1.5 text-sm font-extrabold text-ink">
          <span className={store === "play" ? "text-emerald-600" : "text-slate-800"}>{Icon}</span>
          {label}
        </div>
        <div className="mt-1 text-[11px] font-semibold uppercase tracking-wider text-muted">
          QR orqali yuklab oling
        </div>
      </div>
    </a>
  );
}
