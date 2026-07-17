import { Link } from "react-router-dom";
import { Users } from "lucide-react";
import { Panel } from "./Panel";
import { ScoreBadge } from "./ScoreBadge";
import { Reveal } from "../glass";
import type { ClientRow } from "../../lib/types";

function timeAgo(iso: string): string {
  const d = new Date(iso).getTime();
  const diff = Date.now() - d;
  const m = Math.floor(diff / 60000);
  if (m < 1) return "hozirgina";
  if (m < 60) return `${m} daq oldin`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} soat oldin`;
  const dys = Math.floor(h / 24);
  if (dys < 30) return `${dys} kun oldin`;
  return new Date(iso).toLocaleDateString("uz-UZ");
}

function initials(name: string | null): string {
  if (!name) return "?";
  const parts = name.trim().split(/\s+/);
  return (parts[0]?.[0] ?? "") + (parts[1]?.[0] ?? "");
}

export function RecentClients({ rows, loading }: { rows: ClientRow[]; loading: boolean }) {
  return (
    <Panel
      title="Yangi mijozlar"
      subtitle="So'nggi ro'yxatdan o'tgan foydalanuvchilar"
      icon={<Users size={17} strokeWidth={1.75} />}
      action={
        <Link
          to="/clients"
          className="press rounded-full px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5 dark:text-wine-300"
        >
          Barchasi →
        </Link>
      }
    >
      {loading ? (
        <SkeletonList rows={4} />
      ) : rows.length === 0 ? (
        <p className="py-6 text-center text-sm text-muted">
          Hali mijozlar yo'q
        </p>
      ) : (
        <ul className="space-y-2.5">
          {rows.map((c, i) => (
            <li key={c.id}>
              <Reveal index={i}>
                <Link
                  to={`/clients/${c.id}`}
                  className="flex items-center gap-3 rounded-xl p-2 transition hover:bg-wine-50 dark:hover:bg-wine-900/20"
                >
                  <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-wine/10 text-xs font-black text-wine dark:bg-wine/15 dark:text-wine-300">
                    {initials(c.full_name)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-bold text-ink">
                      {c.full_name ?? "Ismsiz mijoz"}
                    </div>
                    <div className="truncate text-xs text-muted">
                      {c.phone ?? c.email ?? "—"} · {timeAgo(c.created_at)}
                    </div>
                  </div>
                  <ScoreBadge score={c.last_speech_score} />
                </Link>
              </Reveal>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  );
}

export function SkeletonList({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-2.5">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 rounded-xl p-2">
          <div className="h-9 w-9 animate-pulse rounded-lg bg-line/70" />
          <div className="flex-1 space-y-1.5">
            <div className="h-3 w-1/2 animate-pulse rounded bg-line/70" />
            <div className="h-2.5 w-1/3 animate-pulse rounded bg-line/60" />
          </div>
          <div className="h-6 w-10 animate-pulse rounded-full bg-line/60" />
        </div>
      ))}
    </div>
  );
}
