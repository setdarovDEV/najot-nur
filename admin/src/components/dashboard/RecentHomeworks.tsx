import { Link } from "react-router-dom";
import { ClipboardList, ChevronRight } from "lucide-react";
import { Panel } from "./Panel";
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
}: {
  rows: Homework[];
  loading: boolean;
  emptyText?: string;
}) {
  return (
    <Panel
      title="Tekshirish navbatidagi vazifalar"
      subtitle="Kurator tomonidan ko'rib chiqilishi kerak"
      icon={<ClipboardList size={17} strokeWidth={1.75} />}
      action={
        <Link
          to="/homeworks"
          className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5"
        >
          Hammasi <ChevronRight size={12} />
        </Link>
      }
    >
      {loading ? (
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
          {rows.map((hw) => (
            <li key={hw.id}>
              <Link
                to="/homeworks"
                className="block rounded-xl border border-line/70 p-3 transition hover:border-wine/30 hover:bg-wine-50/50"
              >
                <div className="flex items-start justify-between gap-3">
                  <p className="line-clamp-2 text-sm text-ink">
                    {hw.submission_text ??
                      hw.submission_url ??
                      "Matn yuborilmagan"}
                  </p>
                  <span className="shrink-0 rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-700">
                    Yangi
                  </span>
                </div>
                <div className="mt-1.5 flex items-center gap-2 text-[11px] text-muted">
                  <span>{timeAgo(hw.created_at)}</span>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  );
}
