import { useLocation, useNavigate } from "react-router-dom";
import { ArrowLeft, BookOpenText } from "lucide-react";
import { useLang } from "../../lib/i18n";
import { GlassCard, ScoreRing } from "../../components/glass";
import type { VoiceAnalysis } from "../../lib/types";

export function VoiceResultPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const location = useLocation();
  const analysis = (location.state as { analysis?: VoiceAnalysis } | null)?.analysis;

  if (!analysis) {
    return (
      <div className="mx-auto max-w-2xl py-20 text-center text-sm text-muted">
        {t.common.noData}
      </div>
    );
  }

  const errors = analysis.word_errors ?? [];
  const tips = extractTips(analysis);

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/speech/voice")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-6 text-center">
        <h1 className="text-xl font-black text-ink">{t.speech.result}</h1>
        <div className="mt-5 flex flex-wrap items-center justify-center gap-6">
          <ScoreRing value={analysis.overall_score} size={110} />
          <div className="text-left">
            <div className="text-xs font-bold uppercase tracking-wide text-muted">
              {t.speech.overallScore}
            </div>
            <div className="mt-2 flex items-center gap-2">
              <span className="text-xs text-muted">{t.speech.accuracy}</span>
              <ScoreRing value={analysis.accuracy_score} size={44} />
            </div>
          </div>
        </div>
      </GlassCard>

      {analysis.reference_text && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <BookOpenText size={16} className="text-wine" /> {t.speech.references}
          </div>
          <p className="rounded-2xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
            {analysis.reference_text}
          </p>
        </GlassCard>
      )}

      {errors.length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-3 text-sm font-extrabold text-ink">{t.speech.wordErrors}</div>
          <div className="flex flex-wrap gap-2">
            {errors.map((e, i) => (
              <span
                key={i}
                className="rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-bold text-red-600 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400"
              >
                {e.word}
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

      {tips.length > 0 && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 text-sm font-extrabold text-ink">{t.speech.recommendations}</div>
          <ul className="space-y-1.5">
            {tips.map((s, i) => (
              <li key={i} className="text-sm leading-relaxed text-muted">
                • {s}
              </li>
            ))}
          </ul>
        </GlassCard>
      )}
    </div>
  );
}

function extractTips(analysis: VoiceAnalysis): string[] {
  const charStats = analysis.char_stats ?? {};
  const phonemeTips = (charStats.phoneme_tips as Array<{ tip?: string; phoneme?: string }> | null) ?? [];
  const tips = phonemeTips.map((p) => `${p.phoneme ?? ""}: ${p.tip ?? ""}`.trim()).filter(Boolean);
  return tips.slice(0, 8);
}
