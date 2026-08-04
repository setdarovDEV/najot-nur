import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, BookOpenText } from "lucide-react";
import { api, apiError } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { AudioRecorder } from "../../components/AudioRecorder";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import type { PronunciationReference, VoiceAnalysis } from "../../lib/types";

export function VoicePage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [audio, setAudio] = useState<Blob | null>(null);
  const [analyzing, setAnalyzing] = useState(false);

  const refsQ = useQuery({
    queryKey: ["references"],
    queryFn: async () => (await api.get<PronunciationReference[]>("/speech/references")).data,
  });

  const selected = refsQ.data?.find((r) => r.id === selectedId);

  async function submit() {
    if (!selected || !audio) return;
    setAnalyzing(true);
    try {
      const fd = new FormData();
      fd.append("file", audio, "voice.webm");
      fd.append("reference_text", selected.text);
      fd.append("reference_id", selected.id);
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

      <h1 className="text-xl font-black text-ink">{t.home.voiceTest}</h1>
      <p className="mt-1.5 text-sm leading-relaxed text-muted">{t.speech.voiceDescription}</p>

      <div className="mt-5">
        <div className="mb-2 text-sm font-extrabold text-ink">{t.speech.selectReference}</div>
        {refsQ.isLoading ? (
          <div className="py-6"><Spinner /></div>
        ) : (
          <div className="grid gap-2 sm:grid-cols-2">
            {(refsQ.data ?? []).map((r) => (
              <button
                key={r.id}
                type="button"
                onClick={() => setSelectedId(r.id)}
                className={`press rounded-2xl border p-4 text-left transition ${
                  selectedId === r.id
                    ? "border-wine bg-wine-50 dark:bg-wine/20"
                    : "border-line bg-card hover:border-wine/40"
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-extrabold text-ink">{r.title}</span>
                  <StatusPill tone="neutral">{r.difficulty}</StatusPill>
                </div>
                <p className="mt-1.5 line-clamp-2 text-xs leading-relaxed text-muted">{r.text}</p>
              </button>
            ))}
          </div>
        )}
      </div>

      {selected && (
        <GlassCard className="mt-5 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <BookOpenText size={16} className="text-wine" /> {t.speech.references}
          </div>
          <p className="rounded-2xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
            {selected.text}
          </p>
        </GlassCard>
      )}

      <div className="mt-5">
        <AudioRecorder audio={audio} setAudio={setAudio} variant="card" />
      </div>

      <PrimaryButton
        onClick={submit}
        loading={analyzing}
        disabled={!selected || !audio}
        className="mt-4 w-full py-3"
      >
        {analyzing ? t.speech.analyzing : t.speech.analyzeBtn}
      </PrimaryButton>
    </div>
  );
}
