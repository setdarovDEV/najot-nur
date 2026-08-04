import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Eye, Mic } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, Spinner } from "../../components/glass";
import type { ObservationAttempt, SpeechAnalysis } from "../../lib/types";

interface HistoryItem {
  id: string;
  kind: "speech" | "observation";
  score: number | null;
  subtitle?: string | null;
  createdAt: string;
}

export function HistoryPage() {
  const navigate = useNavigate();
  const { t } = useLang();

  const speechQ = useQuery({
    queryKey: ["speech-history"],
    queryFn: async () => (await api.get<SpeechAnalysis[]>("/speech/history")).data,
  });
  const obsQ = useQuery({
    queryKey: ["observation-attempts"],
    queryFn: async () => (await api.get<ObservationAttempt[]>("/observation/attempts")).data,
  });

  const items: HistoryItem[] = [
    ...(speechQ.data ?? []).map((s) => ({
      id: s.id,
      kind: "speech" as const,
      score: s.overall_score,
      subtitle: s.summary,
      createdAt: s.created_at,
    })),
    ...(obsQ.data ?? []).map((a) => ({
      id: a.id,
      kind: "observation" as const,
      score: a.score,
      subtitle: a.summary,
      createdAt: a.created_at,
    })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  const loading = speechQ.isLoading || obsQ.isLoading;

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <h1 className="text-xl font-black text-ink">{t.history.title}</h1>
      <p className="mt-1 text-xs text-muted sm:text-sm">{t.history.subtitle}</p>

      <div className="mt-5 space-y-2">
        {loading ? (
          <div className="py-16"><Spinner /></div>
        ) : items.length === 0 ? (
          <GlassCard className="p-10 text-center text-sm text-muted">{t.history.noData}</GlassCard>
        ) : (
          items.map((item) => (
            <GlassCard key={`${item.kind}-${item.id}`} className="flex items-center gap-4 p-4">
              <div
                className={`grid h-11 w-11 shrink-0 place-items-center rounded-2xl ${
                  item.kind === "speech"
                    ? "bg-wine-50 text-wine dark:bg-wine/20"
                    : "bg-skyblue/10 text-skyblue"
                }`}
              >
                {item.kind === "speech" ? <Mic size={20} /> : <Eye size={20} />}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-extrabold text-ink">
                    {item.kind === "speech" ? t.history.speech : t.history.observation}
                  </span>
                </div>
                {item.subtitle && (
                  <p className="mt-0.5 line-clamp-1 text-xs text-muted">{item.subtitle}</p>
                )}
                <div className="mt-1 text-[11px] text-muted">
                  {new Date(item.createdAt).toLocaleString()}
                </div>
              </div>
              {item.score != null && (
                <span className="shrink-0 text-sm font-black text-wine">{item.score}</span>
              )}
            </GlassCard>
          ))
        )}
      </div>
    </div>
  );
}
