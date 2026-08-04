import { useLocation, useNavigate } from "react-router-dom";
import { ArrowLeft, CheckCircle2, Lightbulb, List } from "lucide-react";
import { useLang } from "../../lib/i18n";
import { GlassCard, ScoreRing } from "../../components/glass";
import type { SpeechAnalysis } from "../../lib/types";

export function TalkResultPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const location = useLocation();
  const analysis = (location.state as { analysis?: SpeechAnalysis } | null)?.analysis;

  if (!analysis) {
    return (
      <div className="mx-auto max-w-2xl py-20 text-center text-sm text-muted">
        {t.common.noData}
      </div>
    );
  }

  const strengths = ((analysis.details?.strengths as unknown[] | null) ?? []).map(String);
  const improvements = ((analysis.details?.improvements as unknown[] | null) ?? []).map(String);
  const fillers = analysis.filler_words ?? {};

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/speech")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-6 text-center">
        <h1 className="text-xl font-black text-ink">{t.speech.result}</h1>
        <div className="mt-5 flex justify-center">
          <ScoreRing value={analysis.overall_score} size={110} />
        </div>
        <div className="mt-4 text-xs font-bold uppercase tracking-wide text-muted">
          {t.speech.overallScore}
        </div>
      </GlassCard>

      <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
        <ScoreTile label={t.speech.meaning} value={analysis.meaning_score} />
        <ScoreTile label={t.speech.fluency} value={analysis.fluency_score} />
        <ScoreTile label={t.speech.info} value={undefined} infoText={analysis.info_balance ?? "—"} />
      </div>

      {Object.keys(fillers).length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <List size={16} className="text-wine" /> {t.speech.parasites}
          </div>
          <div className="flex flex-wrap gap-2">
            {Object.entries(fillers).map(([w, n]) => (
              <span key={w} className="rounded-full bg-wine-50 px-3 py-1 text-xs font-bold text-wine dark:bg-wine/20">
                “{w}” × {n}
              </span>
            ))}
          </div>
        </GlassCard>
      )}

      {analysis.summary && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 text-sm font-extrabold text-ink">{t.speech.summary}</div>
          <p className="text-sm leading-relaxed text-muted">{analysis.summary}</p>
        </GlassCard>
      )}

      {strengths.length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <CheckCircle2 size={16} className="text-success" /> {t.speech.recommendations}
          </div>
          <ul className="space-y-1.5">
            {strengths.map((s, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-muted">
                <CheckCircle2 size={14} className="mt-0.5 shrink-0 text-success" />
                {s}
              </li>
            ))}
          </ul>
        </GlassCard>
      )}

      {improvements.length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <Lightbulb size={16} className="text-warning" /> {t.speech.recommendations}
          </div>
          <ul className="space-y-1.5">
            {improvements.map((s, i) => (
              <li key={i} className="flex items-start gap-2 text-sm text-muted">
                <Lightbulb size={14} className="mt-0.5 shrink-0 text-warning" />
                {s}
              </li>
            ))}
          </ul>
        </GlassCard>
      )}
    </div>
  );
}

function ScoreTile({
  label,
  value,
  infoText,
}: {
  label: string;
  value?: number | null;
  infoText?: string;
}) {
  return (
    <GlassCard className="p-4 text-center">
      <div className="text-xl font-black text-ink">
        {value != null ? value : infoText}
      </div>
      <div className="mt-1 text-[11px] font-bold uppercase tracking-wide text-muted">
        {label}
      </div>
    </GlassCard>
  );
}
