import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, FileText, Mic } from "lucide-react";
import { api, apiError } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { AudioRecorder } from "../../components/AudioRecorder";
import { GlassCard, GlassTextarea, PrimaryButton, SecondaryButton } from "../../components/glass";
import type { SpeechAnalysis } from "../../lib/types";

export function TalkPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [mode, setMode] = useState<"record" | "text">("record");
  const [audio, setAudio] = useState<Blob | null>(null);
  const [transcript, setTranscript] = useState("");
  const [analyzing, setAnalyzing] = useState(false);

  async function submit() {
    setAnalyzing(true);
    try {
      let result: SpeechAnalysis;
      if (mode === "record" && audio) {
        const fd = new FormData();
        fd.append("file", audio, "talk.webm");
        fd.append("language", "uz");
        const res = await api.post<SpeechAnalysis>("/speech/free-talk", fd);
        result = res.data;
      } else {
        if (transcript.trim().length < 10) {
          toast.error(t.speech.transcriptPlaceholder);
          return;
        }
        const res = await api.post<SpeechAnalysis>("/speech/analyze", {
          transcript: transcript.trim(),
          duration_sec: Math.round(transcript.trim().split(/\s+/).length / 2.5),
        });
        result = res.data;
      }
      navigate("/speech/talk/result", { state: { analysis: result } });
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

      <h1 className="text-xl font-black text-ink">{t.home.freeTalk}</h1>
      <p className="mt-1.5 text-sm leading-relaxed text-muted">{t.speech.talkDescription}</p>

      <div className="mt-5 flex gap-2">
        <button
          type="button"
          onClick={() => setMode("record")}
          className={`press flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-bold transition ${
            mode === "record"
              ? "border-wine bg-wine text-white"
              : "border-line bg-card text-muted hover:text-wine"
          }`}
        >
          <Mic size={15} /> {t.speech.recordBtn}
        </button>
        <button
          type="button"
          onClick={() => setMode("text")}
          className={`press flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-bold transition ${
            mode === "text"
              ? "border-wine bg-wine text-white"
              : "border-line bg-card text-muted hover:text-wine"
          }`}
        >
          <FileText size={15} /> {t.speech.orPasteText}
        </button>
      </div>

      <div className="mt-5">
        {mode === "record" ? (
          <AudioRecorder audio={audio} setAudio={setAudio} variant="card" />
        ) : (
          <GlassCard className="p-5">
            <GlassTextarea
              value={transcript}
              onChange={(e) => setTranscript(e.target.value)}
              placeholder={t.speech.transcriptPlaceholder}
              rows={8}
            />
          </GlassCard>
        )}
      </div>

      <PrimaryButton
        onClick={submit}
        loading={analyzing}
        disabled={mode === "record" ? !audio : transcript.trim().length < 10}
        className="mt-4 w-full py-3"
      >
        {analyzing ? t.speech.analyzing : t.speech.analyzeBtn}
      </PrimaryButton>
      <div className="mt-4 flex justify-center">
        <SecondaryButton onClick={() => navigate("/speech/practice")}>
          {t.speech.practice}
        </SecondaryButton>
      </div>
    </div>
  );
}
