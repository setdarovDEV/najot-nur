import { useLocation, useNavigate } from "react-router-dom";
import { ArrowLeft, RotateCcw } from "lucide-react";
import { useLang } from "../../lib/i18n";
import { GlassCard, PrimaryButton, ScoreRing } from "../../components/glass";
import type { ObservationAttempt } from "../../lib/types";

export function ObservationResultPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const location = useLocation();
  const attempt = (location.state as { attempt?: ObservationAttempt } | null)?.attempt;

  if (!attempt) {
    return (
      <div className="mx-auto max-w-2xl py-20 text-center text-sm text-muted">
        {t.common.noData}
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/observation")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-8 text-center">
        <h1 className="text-xl font-black text-ink">{t.observation.score}</h1>
        {attempt.score != null && (
          <div className="mt-5 flex justify-center">
            <ScoreRing value={attempt.score} size={110} />
          </div>
        )}
        {attempt.summary && (
          <p className="mx-auto mt-5 max-w-md text-sm leading-relaxed text-muted">
            {attempt.summary}
          </p>
        )}
        <div className="mt-6 flex justify-center">
          <PrimaryButton onClick={() => navigate("/observation")}>
            <RotateCcw size={15} /> {t.observation.attemptAgain}
          </PrimaryButton>
        </div>
      </GlassCard>

      {attempt.analysis && Object.keys(attempt.analysis).length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 text-sm font-extrabold text-ink">{t.observation.analysis}</div>
          <pre className="whitespace-pre-wrap rounded-2xl border border-line bg-surface p-4 text-xs leading-relaxed text-muted">
            {JSON.stringify(attempt.analysis, null, 2)}
          </pre>
        </GlassCard>
      )}
    </div>
  );
}
