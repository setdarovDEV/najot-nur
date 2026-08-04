import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Headphones, Mic, Send } from "lucide-react";
import { api, apiError, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { AudioRecorder } from "../../components/AudioRecorder";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import type { Practicum, PracticumSubmission } from "../../lib/types";

export function PracticumDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [audio, setAudio] = useState<Blob | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const practicumQ = useQuery({
    queryKey: ["practicum", id],
    queryFn: async () => (await api.get<Practicum>(`/practicums/${id}`)).data,
    enabled: !!id,
  });
  const submissionQ = useQuery({
    queryKey: ["practicum-submission", id],
    queryFn: async () =>
      (await api.get<PracticumSubmission | null>(`/practicums/${id}/my-submission`)).data,
    enabled: !!id,
  });

  const practicum = practicumQ.data;
  const submission = submissionQ.data;
  const expertAudio = mediaUrl(practicum?.expert_audio_url);

  async function submit() {
    if (!audio || !id) return;
    setSubmitting(true);
    const fd = new FormData();
    fd.append("file", audio, "recording.webm");
    fd.append("language", "uz");
    try {
      await api.post(`/practicums/${id}/submit`, fd);
      toast.success(t.practicums.submitted);
      submissionQ.refetch();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  if (practicumQ.isLoading || !practicum) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        type="button"
        onClick={() => navigate("/practicums")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-6">
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
              <Mic size={22} />
            </div>
            <div>
              <h1 className="text-xl font-black text-ink">{practicum.title}</h1>
              {practicum.category && (
                <div className="mt-1 text-xs text-muted">
                  {t.practicums.category}: {practicum.category}
                </div>
              )}
            </div>
          </div>
          {practicum.is_free ? (
            <StatusPill tone="success">{t.common.free}</StatusPill>
          ) : (
            <span className="text-sm font-black text-ink">
              {Number(practicum.price).toLocaleString("uz-UZ")} so'm
            </span>
          )}
        </div>

        {practicum.description && (
          <p className="mt-4 text-sm leading-relaxed text-muted">{practicum.description}</p>
        )}
      </GlassCard>

      {expertAudio && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-3 flex items-center gap-2 text-sm font-extrabold text-ink">
            <Headphones size={16} className="text-wine" /> {t.practicums.listenExpert}
          </div>
          <audio controls className="w-full" src={expertAudio} />
        </GlassCard>
      )}

      {practicum.expert_text && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 text-sm font-extrabold text-ink">{t.practicums.expertText}</div>
          <p className="whitespace-pre-line rounded-2xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
            {practicum.expert_text}
          </p>
        </GlassCard>
      )}

      {/* Record + submit */}
      <div className="mt-4">
        <AudioRecorder audio={audio} setAudio={setAudio} variant="card" />
        <PrimaryButton
          onClick={submit}
          loading={submitting}
          disabled={!audio}
          className="mt-3 w-full py-3"
        >
          {submitting ? <Send size={15} /> : <Send size={15} />}
          {submitting ? t.practicums.processing : t.practicums.submit}
        </PrimaryButton>
      </div>

      {/* My result */}
      {submission && (
        <GlassCard className="mt-6 p-5">
          <div className="mb-3 flex items-center justify-between gap-2">
            <span className="text-sm font-extrabold text-ink">{t.practicums.myResult}</span>
            <StatusPill tone={submission.status === "approved" ? "success" : "warning"}>
              {submission.status}
            </StatusPill>
          </div>
          {submission.overall_score != null && (
            <div className="flex items-center gap-4">
              <div
                className="grid h-16 w-16 shrink-0 place-items-center rounded-full score-ring"
                style={{
                  background: `conic-gradient(${submission.overall_score >= 60 ? "#1fa971" : "#f5a524"} ${submission.overall_score * 3.6}deg, rgba(0,0,0,0.08) 0deg)`,
                }}
              >
                <div className="grid h-13 w-13 place-items-center rounded-full bg-card">
                  <span className="text-lg font-black text-ink">{submission.overall_score}</span>
                </div>
              </div>
              <div className="min-w-0 flex-1 text-xs text-muted">
                {submission.transcript && (
                  <p className="line-clamp-3 leading-relaxed">“{submission.transcript}”</p>
                )}
              </div>
            </div>
          )}
          {submission.audio_url && (
            <audio controls src={mediaUrl(submission.audio_url)!} className="mt-3 w-full" />
          )}
        </GlassCard>
      )}
    </div>
  );
}
