import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { api } from "../lib/api";
import { ScoreBadge } from "./ClientsPage";
import { useLang } from "../lib/i18n";

interface SpeechRow {
  id: string;
  overall_score: number | null;
  summary: string | null;
  created_at: string;
}
interface ClientDetail {
  id: string;
  full_name: string | null;
  phone: string | null;
  email: string | null;
  is_verified: boolean;
  created_at: string;
  speech_analyses: SpeechRow[];
}

export function ClientDetailPage() {
  const { id } = useParams();
  const { t } = useLang();
  const { data, isLoading } = useQuery({
    queryKey: ["client", id],
    queryFn: async () =>
      (await api.get<ClientDetail>(`/admin/clients/${id}`)).data,
  });

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <Link to="/clients" className="text-sm font-semibold text-wine">
        {t.clients.backToList}
      </Link>

      {isLoading || !data ? (
        <p className="mt-6 text-muted">{t.common.loading}</p>
      ) : (
        <>
          <div className="mt-4 rounded-2xl bg-gradient-to-br from-wine to-wine-deep p-5 text-white sm:p-6">
            <h1 className="text-xl font-extrabold sm:text-2xl">
              {data.full_name ?? t.clients.unnamed}
            </h1>
            <div className="mt-2 flex flex-wrap gap-x-6 gap-y-1 text-sm text-white/85">
              <span>📞 {data.phone ?? "—"}</span>
              <span>✉️ {data.email ?? "—"}</span>
              <span>
                {new Date(data.created_at).toLocaleDateString()}
              </span>
            </div>
            <code className="mt-2 block text-xs text-white/60">ID: {data.id}</code>
          </div>

          <h2 className="mb-3 mt-8 text-lg font-bold text-ink">{t.clients.speechAnalyses}</h2>
          {data.speech_analyses.length === 0 ? (
            <p className="rounded-xl border border-line bg-card p-5 text-muted">
              {t.clients.noAnalyses}
            </p>
          ) : (
            <div className="space-y-3">
              {data.speech_analyses.map((s) => (
                <div
                  key={s.id}
                  className="rounded-2xl border border-line bg-card p-5"
                >
                  <div className="mb-2 flex items-center justify-between">
                    {s.overall_score != null ? (
                      <ScoreBadge score={s.overall_score} />
                    ) : (
                      <span className="text-muted">—</span>
                    )}
                    <span className="text-xs text-muted">
                      {new Date(s.created_at).toLocaleString()}
                    </span>
                  </div>
                  <p className="text-sm leading-relaxed text-ink">
                    {s.summary ?? "—"}
                  </p>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
