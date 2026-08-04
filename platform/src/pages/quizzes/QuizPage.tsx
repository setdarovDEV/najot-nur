import { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, RotateCcw } from "lucide-react";
import { api, apiError } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import type { QuizDetail, QuizAttempt } from "../../lib/types";

export function QuizPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();

  const quizQ = useQuery({
    queryKey: ["quiz", id],
    queryFn: async () => (await api.get<QuizDetail>(`/quizzes/${id}`)).data,
    enabled: !!id,
  });

  const quiz = quizQ.data;
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [result, setResult] = useState<QuizAttempt | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const questions = useMemo(() => quiz?.questions ?? [], [quiz]);

  async function submit() {
    if (!quiz) return;
    if (Object.keys(answers).length !== questions.length) {
      toast.error(t.quizzes.yourAnswer + "…");
      return;
    }
    setSubmitting(true);
    try {
      const ordered = questions.map((q) => answers[q.question] ?? -1);
      const res = await api.post<QuizAttempt>(`/quizzes/${quiz.id}/attempt`, {
        answers: ordered,
      });
      setResult(res.data);
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  if (quizQ.isLoading || !quiz) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        type="button"
        onClick={() => navigate("/quizzes")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      {!result && (
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <h1 className="text-xl font-black text-ink">{quiz.title}</h1>
          <StatusPill tone="neutral">{quiz.difficulty}</StatusPill>
          <span className="text-xs text-muted">{t.quizzes.questions(questions.length)}</span>
        </div>
      )}

      {result ? (
        <GlassCard className="p-8 text-center">
          <div
            className="mx-auto grid h-28 w-28 place-items-center rounded-full score-ring"
            style={{
              background: `conic-gradient(${result.score >= 60 ? "#1fa971" : "#f5a524"} ${result.score * 3.6}deg, rgba(0,0,0,0.08) 0deg)`,
            }}
          >
            <div className="grid h-24 w-24 place-items-center rounded-full bg-card">
              <div>
                <div className="text-3xl font-black text-ink">{result.score}</div>
                <div className="text-[10px] font-bold text-muted">{t.quizzes.score}</div>
              </div>
            </div>
          </div>
          <div className="mt-4 text-sm font-bold text-ink">
            {t.quizzes.correct(result.correct_count)} · {t.common.of} {result.total_count}
          </div>
          <div className="mt-2">
            <StatusPill tone={result.score >= 60 ? "success" : "warning"}>
              {result.score >= 60 ? t.courses.passed : t.courses.notPassed}
            </StatusPill>
          </div>
          <div className="mt-6 flex justify-center gap-3">
            <PrimaryButton
              onClick={() => {
                setResult(null);
                setAnswers({});
              }}
            >
              <RotateCcw size={15} /> {t.quizzes.retry}
            </PrimaryButton>
          </div>
        </GlassCard>
      ) : (
        <>
          <div className="space-y-4">
            {questions.map((q, qi) => (
              <GlassCard key={qi} className="p-5">
                <p className="text-sm font-bold text-ink">
                  {qi + 1}. {q.question}
                </p>
                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  {q.options.map((opt, oi) => {
                    const selected = answers[q.question] === oi;
                    return (
                      <button
                        key={oi}
                        type="button"
                        onClick={() =>
                          setAnswers((a) => ({ ...a, [q.question]: oi }))
                        }
                        className={`press flex items-center gap-2.5 rounded-2xl border px-3.5 py-2.5 text-left text-sm font-semibold transition ${
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
              </GlassCard>
            ))}
          </div>
          <PrimaryButton onClick={submit} loading={submitting} className="mt-6 w-full py-3">
            {submitting ? t.common.loading : t.quizzes.results}
          </PrimaryButton>
        </>
      )}
    </div>
  );
}
