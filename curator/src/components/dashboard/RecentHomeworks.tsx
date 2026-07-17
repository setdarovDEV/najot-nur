import { Link } from "react-router-dom";
import { ClipboardList, ChevronRight } from "lucide-react";
import { Panel } from "./Panel";
import { Reveal, StatusPill } from "../glass";
import type { Homework } from "../../lib/types";

function timeAgo(iso: string): string {
  const d = new Date(iso).getTime();
  const diff = Date.now() - d;
  const m = Math.floor(diff / 60000);
  if (m < 60) return `${m < 1 ? 1 : m} daq oldin`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} soat oldin`;
  const dys = Math.floor(h / 24);
  if (dys < 30) return `${dys} kun oldin`;
  return new Date(iso).toLocaleDateString("uz-UZ");
}

export function RecentHomeworks({
  rows,
  loading,
  emptyText = "Tekshirilmagan vazifalar yo'q",
  className,
  asPanel = true,
}: {
  rows: Homework[];
  loading: boolean;
  emptyText?: string;
  className?: string;
  asPanel?: boolean;
}) {
  const body = loading ? (
    <div className="space-y-2.5">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="h-16 animate-pulse rounded-xl bg-line/50" />
      ))}
    </div>
  ) : rows.length === 0 ? (
    <div className="rounded-xl border border-dashed border-line py-8 text-center text-sm text-muted">
      {emptyText} 🎉
    </div>
  ) : (
    <ul className="space-y-2">
      {rows.map((hw, i) => (
        <li key={hw.id}>
          <Reveal index={i}>
            <Link
              to="/homeworks"
              className="block rounded-xl border border-line/70 p-3 transition hover:border-wine/30 hover:bg-wine-50/50 dark:hover:bg-wine-900/20"
            >
              <div className="flex items-start justify-between gap-3">
                <p className="line-clamp-2 text-sm text-ink">
                  {hw.submission_text ??
                    hw.submission_url ??
                    "Matn yuborilmagan"}
                </p>
                <StatusPill tone="warning" className="shrink-0">
                  Yangi
                </StatusPill>
              </div>
              <div className="mt-1.5 flex items-center gap-2 text-[11px] text-muted">
                <span>{timeAgo(hw.created_at)}</span>
              </div>
            </Link>
          </Reveal>
        </li>
      ))}
    </ul>
  );

  if (!asPanel) return <div className={className}>{body}</div>;

  return (
    <Panel
      title="Tekshirish navbatidagi vazifalar"
      subtitle="Kurator tomonidan ko'rib chiqilishi kerak"
      icon={<ClipboardList size={17} strokeWidth={1.75} />}
      action={
        <Link
          to="/homeworks"
          className="press inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5 dark:text-wine-300"
        >
          Hammasi <ChevronRight size={12} />
        </Link>
      }
      className={className}
    >
      {body}
    </Panel>
  );
}
