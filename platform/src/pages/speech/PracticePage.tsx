import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, Sparkles } from "lucide-react";
import { api, apiError } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { AudioRecorder } from "../../components/AudioRecorder";
import { GlassCard, GlassSelect, PrimaryButton, SecondaryButton, Spinner } from "../../components/glass";
import type { VoiceAnalysis } from "../../lib/types";

export function PracticePage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [generated, setGenerated] = useState<{ text: string; title: string } | null>(null);
  const [difficulty, setDifficulty] = useState<"easy" | "medium" | "hard">("medium");
  const [generating, setGenerating] = useState(false);
  const [audio, setAudio] = useState<Blob | null>(null);
  const [analyzing, setAnalyzing] = useState(false);

  async function generate() {
    setGenerating(true);
    try {
      const fd = new FormData();
      fd.append("difficulty", difficulty);
      const res = await api.post<{ text: string; title: string }>("/speech/practice/generate", fd);
      setGenerated(res.data);
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setGenerating(false);
    }
  }

  async function submit() {
    if (!generated || !audio) return;
    setAnalyzing(true);
    try {
      const fd = new FormData();
      fd.append("file", audio, "practice.webm");
      fd.append("reference_text", generated.text);
      fd.append("language", "uz");
      const res = await api.post<VoiceAnalysis>("/speech/voice/analyze-audio", fd);
      navigate("/speech/voice/result", { state: { analysis: res.data } });
    } catch (err) {
      toast.error(apiError(err));
      setAnalyzing(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/speech")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <h1 className="text-xl font-black text-ink">{t.speech.practice}</h1>
      <p className="mt-1.5 text-sm leading-relaxed text-muted">{t.speech.practiceDescription}</p>

      <GlassCard className="mt-5 p-5">
        <div className="mb-3 flex flex-col gap-3 sm:flex-row sm:items-end">
          <div className="flex-1">
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.speech.difficulty}
            </label>
            <GlassSelect
              value={difficulty}
              onChange={(e) => setDifficulty(e.target.value as "easy" | "medium" | "hard")}
            >
              <option value="easy">{t.speech.easy}</option>
              <option value="medium">{t.speech.medium}</option>
              <option value="hard">{t.speech.hard}</option>
            </GlassSelect>
          </div>
          <PrimaryButton onClick={generate} loading={generating}>
            <Sparkles size={15} /> {t.speech.selectReference}
          </PrimaryButton>
        </div>

        {generating ? (
          <div className="py-8"><Spinner /></div>
        ) : generated ? (
          <div>
            <div className="mb-2 text-sm font-extrabold text-ink">{generated.title}</div>
            <p className="rounded-2xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
              {generated.text}
            </p>
          </div>
        ) : (
          <p className="rounded-2xl border border-dashed border-line bg-surface/50 p-4 text-center text-xs text-muted">
            {t.speech.practiceDescription}
          </p>
        )}
      </GlassCard>

      {generated && (
        <>
          <div className="mt-5">
            <AudioRecorder audio={audio} setAudio={setAudio} variant="card" />
          </div>
          <PrimaryButton
            onClick={submit}
            loading={analyzing}
            disabled={!audio}
            className="mt-4 w-full py-3"
          >
            {analyzing ? t.speech.analyzing : t.speech.analyzeBtn}
          </PrimaryButton>
        </>
      )}

      <div className="mt-4 text-center">
        <SecondaryButton onClick={() => navigate("/speech/talk")}>
          {t.home.freeTalk}
        </SecondaryButton>
      </div>
    </div>
  );
}
