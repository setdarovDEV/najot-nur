import { useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import type { ClientRow, Page } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

export function ClientsPage() {
  const [q, setQ] = useState("");
  const [page, setPage] = useState(1);
  const navigate = useNavigate();
  const { t } = useLang();
  const size = 20;

  const { data, isLoading } = useQuery({
    queryKey: ["clients", q, page],
    queryFn: async () =>
      (
        await api.get<Page<ClientRow>>("/admin/clients", {
          params: { q: q || undefined, page, size },
        })
      ).data,
    placeholderData: keepPreviousData,
  });

  const totalPages = data ? Math.max(1, Math.ceil(data.total / size)) : 1;

  return (
    <div className="p-8">
      <PageHeader
        title={t.clients.title}
        subtitle={data ? t.clients.subtitle(data.total) : t.common.loading}
        actions={
          <input
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setPage(1);
            }}
            placeholder={t.clients.searchPlaceholder}
            className="w-72 rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
          />
        }
      />

      <div className="overflow-hidden rounded-2xl border border-line bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-line bg-wine-50 text-left text-muted dark:bg-wine-900/20">
              <th className="px-5 py-3 font-semibold">{t.clients.name}</th>
              <th className="px-5 py-3 font-semibold">{t.clients.phone}</th>
              <th className="px-5 py-3 font-semibold">{t.clients.email}</th>
              <th className="px-5 py-3 font-semibold">{t.clients.speechScore}</th>
              <th className="px-5 py-3 font-semibold">{t.clients.status}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-muted">
                  {t.common.loading}
                </td>
              </tr>
            )}
            {data?.items.map((c) => (
              <tr
                key={c.id}
                onClick={() => navigate(`/clients/${c.id}`)}
                className="cursor-pointer border-b border-line/60 transition hover:bg-wine-50 dark:hover:bg-wine-900/20"
              >
                <td className="px-5 py-3 font-semibold text-ink">
                  {c.full_name ?? "—"}
                </td>
                <td className="px-5 py-3 text-ink">{c.phone ?? "—"}</td>
                <td className="px-5 py-3 text-ink">{c.email ?? "—"}</td>
                <td className="px-5 py-3">
                  {c.last_speech_score != null ? (
                    <ScoreBadge score={c.last_speech_score} />
                  ) : (
                    <span className="text-muted">—</span>
                  )}
                </td>
                <td className="px-5 py-3">
                  {c.is_verified ? (
                    <span className="rounded-full bg-green-100 px-2.5 py-1 text-xs font-semibold text-green-700 dark:bg-green-900/30 dark:text-green-400">
                      {t.common.verified}
                    </span>
                  ) : (
                    <span className="rounded-full bg-line px-2.5 py-1 text-xs font-semibold text-muted">
                      {t.common.unverified}
                    </span>
                  )}
                </td>
              </tr>
            ))}
            {data && data.items.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-muted">
                  {t.clients.noClients}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="mt-4 flex items-center justify-between text-sm">
        <span className="text-muted">
          {page} / {totalPages}
        </span>
        <div className="flex gap-2">
          <button
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
            className="rounded-lg border border-line px-4 py-2 text-ink disabled:opacity-50 hover:bg-wine-50 dark:hover:bg-wine-900/20"
          >
            ←
          </button>
          <button
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
            className="rounded-lg border border-line px-4 py-2 text-ink disabled:opacity-50 hover:bg-wine-50 dark:hover:bg-wine-900/20"
          >
            →
          </button>
        </div>
      </div>
    </div>
  );
}

export function ScoreBadge({ score }: { score: number }) {
  const color =
    score >= 80
      ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
      : score >= 60
        ? "bg-wine-100 text-wine dark:bg-wine-900/20 dark:text-wine-300"
        : score >= 40
          ? "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
          : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400";
  return (
    <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${color}`}>
      {score}
    </span>
  );
}
