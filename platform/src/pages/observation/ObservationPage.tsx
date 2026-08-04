import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ChevronLeft, ChevronRight, Eye } from "lucide-react";
import { api, apiError, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import type { ObservationAttempt, ObservationTest } from "../../lib/types";

export function ObservationPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [submitting, setSubmitting] = useState(false);

  const testsQ = useQuery({
    queryKey: ["observation-tests"],
    queryFn: async () => (await api.get<ObservationTest[]>("/observation/tests")).data,
  });

  const tests = testsQ.data ?? [];
  const test = tests[current];
  const answered = Object.keys(answers).length;

  async function submit() {
    setSubmitting(true);
    try {
      const payload = tests.map((ts) => ({
        test_id: ts.id,
        selected_option: answers[ts.id] ?? null,
      }));
      const res = await api.post<ObservationAttempt>("/observation/submit", {
        answers: payload,
      });
      navigate("/observation/result", { state: { attempt: res.data } });
    } catch (err) {
      toast.error(apiError(err));
      setSubmitting(false);
    }
  }

  if (testsQ.isLoading || !tests.length) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  const media = mediaUrl(test.media_url);

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-6">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
              <Eye size={20} />
            </div>
            <div>
              <div className="text-sm font-extrabold text-ink">{t.observation.title}</div>
              <div className="text-[11px] text-muted">
                {t.observation.questionsLeft(tests.length - current - 1)}
              </div>
            </div>
          </div>
          <StatusPill tone="neutral">
            {current + 1} / {tests.length}
          </StatusPill>
        </div>

        <div className="mb-5 h-2 overflow-hidden rounded-full bg-wine/10">
          <div
            className="h-full rounded-full bg-wine transition-all"
            style={{ width: `${((current + 1) / tests.length) * 100}%` }}
          />
        </div>

        {media && (
          <div className="mb-4 overflow-hidden rounded-2xl border border-line">
            {test.media_type === "video" ? (
              <video controls className="w-full" src={media} />
            ) : (
              <img src={media} alt={test.title} className="w-full" />
            )}
          </div>
        )}

        <h2 className="text-base font-extrabold text-ink">{test.title}</h2>
        <p className="mt-1.5 text-sm leading-relaxed text-muted">{test.prompt}</p>

        <div className="mt-5 space-y-2">
          {(test.options ?? []).map((opt, oi) => {
            const selected = answers[test.id] === oi;
            return (
              <button
                key={oi}
                type="button"
                onClick={() => setAnswers((a) => ({ ...a, [test.id]: oi }))}
                className={`press flex w-full items-center gap-3 rounded-2xl border px-4 py-3 text-left text-sm font-semibold transition ${
                  selected
                    ? "border-wine bg-wine-50 text-wine dark:bg-wine/20"
                    : "border-line bg-card text-ink hover:border-wine/40"
                }`}
              >
                <span
                  className={`grid h-5 w-5 shrink-0 place-items-center rounded-full border text-[10px] font-black ${
                    selected ? "border-wine bg-wine text-white" : "border-line text-muted"
                  }`}
                >
                  {String.fromCharCode(65 + oi)}
                </span>
                {opt}
              </button>
            );
          })}
        </div>

        <div className="mt-6 flex items-center justify-between">
          <button
            type="button"
            onClick={() => setCurrent((c) => Math.max(0, c - 1))}
            disabled={current === 0}
            className="press flex items-center gap-1 rounded-full border border-line px-4 py-2.5 text-xs font-bold text-ink transition hover:border-wine/40 disabled:opacity-40"
          >
            <ChevronLeft size={14} /> {t.common.back}
          </button>

          {current < tests.length - 1 ? (
            <PrimaryButton
              onClick={() => setCurrent((c) => Math.min(tests.length - 1, c + 1))}
              disabled={answers[test.id] === undefined}
            >
              {t.common.next} <ChevronRight size={15} />
            </PrimaryButton>
          ) : (
            <PrimaryButton onClick={submit} loading={submitting} disabled={answered < tests.length}>
              {submitting ? t.observation.analyzing : t.observation.submit}
            </PrimaryButton>
          )}
        </div>
      </GlassCard>
    </div>
  );
}
