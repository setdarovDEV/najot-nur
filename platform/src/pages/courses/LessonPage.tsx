import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  CheckCircle2,
  ClipboardList,
  Clock,
  Mic,
  PlayCircle,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, GlassTextarea, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import type { Homework, LessonDetail } from "../../lib/types";

export function LessonPage() {
  const { id, lessonId } = useParams<{ id: string; lessonId: string }>();
  const navigate = useNavigate();
  const { t } = useLang();

  const lessonQ = useQuery({
    queryKey: ["lesson", lessonId],
    queryFn: async () => (await api.get<LessonDetail>(`/courses/lessons/${lessonId}`)).data,
    enabled: !!lessonId,
  });
  const homeworkQ = useQuery({
    queryKey: ["homework", lessonId],
    queryFn: async () => (await api.get<Homework | null>(`/courses/lessons/${lessonId}/my-homework`)).data,
    enabled: !!lessonId,
  });

  const lesson = lessonQ.data;

  if (lessonQ.isLoading || !lesson) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        type="button"
        onClick={() => navigate(`/courses/${id}/learn`)}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <h1 className="text-xl font-black text-ink">{lesson.title}</h1>
      {lesson.description && (
        <p className="mt-1.5 text-sm leading-relaxed text-muted">{lesson.description}</p>
      )}
      <div className="mt-2 flex items-center gap-2 text-xs text-muted">
        <Clock size={13} /> {Math.round(lesson.duration_sec / 60)} {t.common.minutes}
        {lesson.is_voice_exercise && (
          <StatusPill tone="warning">{t.courses.voiceExercise}</StatusPill>
        )}
      </div>

      {lesson.video_url && <VideoPlayer url={mediaUrl(lesson.video_url)!} />}

      {lesson.is_voice_exercise && lesson.voice_exercise_prompt && (
        <GlassCard className="mt-4 p-5">
          <div className="mb-2 flex items-center gap-2 text-sm font-extrabold text-ink">
            <Mic size={16} className="text-wine" /> {t.courses.voiceExercise}
          </div>
          <p className="rounded-2xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
            {lesson.voice_exercise_prompt}
          </p>
          <a
            href={`/speech/voice`}
            className="mt-4 inline-flex items-center gap-2 text-sm font-bold text-wine hover:underline"
          >
            <PlayCircle size={16} /> {t.speech.voiceTest} →
          </a>
        </GlassCard>
      )}

      {lesson.questions.length > 0 && (
        <LessonQuiz lesson={lesson} onDone={() => lessonQ.refetch()} />
      )}

      {lesson.is_completed ? (
        <div className="mt-6 flex items-center gap-3 rounded-2xl border border-success/25 bg-success/10 p-4 text-sm font-bold text-success">
          <CheckCircle2 size={20} /> {t.courses.lessonCompleted}
        </div>
      ) : (
        <CompleteLesson lessonId={lessonId!} onDone={() => lessonQ.refetch()} />
      )}

      <HomeworkSection homework={homeworkQ.data} lessonId={lessonId!} />
    </div>
  );
}

function VideoPlayer({ url }: { url: string }) {
  return (
    <div className="mt-5 overflow-hidden rounded-3xl border border-line bg-black shadow-lg">
      <video controls className="aspect-video w-full" src={url} />
    </div>
  );
}

function LessonQuiz({ lesson, onDone }: { lesson: LessonDetail; onDone: () => void }) {
  const { t } = useLang();
  const toast = useToast();
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [result, setResult] = useState<{ score: number; correct: number; total: number; passed: boolean } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function submit() {
    if (Object.keys(answers).length !== lesson.questions.length) {
      toast.error(t.quizzes.yourAnswer + "…");
      return;
    }
    setSubmitting(true);
    try {
      const res = await api.post(`/courses/lessons/${lesson.id}/quiz`, { answers });
      setResult(res.data);
      onDone();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <GlassCard className="mt-6 p-5">
      <div className="mb-4 flex items-center gap-2 text-sm font-extrabold text-ink">
        <ClipboardList size={16} className="text-wine" /> {t.courses.quiz}
      </div>

      {result ? (
        <div className="text-center">
          <div
            className="mx-auto grid h-24 w-24 place-items-center rounded-full score-ring"
            style={{
              background: `conic-gradient(${result.passed ? "#1fa971" : "#f5a524"} ${result.score * 3.6}deg, rgba(0,0,0,0.08) 0deg)`,
            }}
          >
            <div className="grid h-20 w-20 place-items-center rounded-full bg-card">
              <div>
                <div className="text-xl font-black text-ink">{result.score}</div>
                <div className="text-[10px] font-bold text-muted">{t.quizzes.score}</div>
              </div>
            </div>
          </div>
          <div className="mt-3 text-sm font-bold text-ink">
            {t.quizzes.correct(result.correct)} · {t.common.of} {result.total}
          </div>
          <div className="mt-1">
            <StatusPill tone={result.passed ? "success" : "warning"}>
              {result.passed ? t.courses.passed : t.courses.notPassed}
            </StatusPill>
          </div>
        </div>
      ) : (
        <>
          <div className="space-y-4">
            {lesson.questions.map((q, qi) => (
              <div key={q.id}>
                <p className="text-sm font-bold text-ink">
                  {qi + 1}. {q.question}
                </p>
                <div className="mt-2 grid gap-2 sm:grid-cols-2">
                  {q.options.map((opt, oi) => {
                    const selected = answers[q.id] === oi;
                    return (
                      <button
                        key={oi}
                        type="button"
                        onClick={() => setAnswers((a) => ({ ...a, [q.id]: oi }))}
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
              </div>
            ))}
          </div>
          <PrimaryButton onClick={submit} loading={submitting} className="mt-5 w-full">
            {t.courses.quizScore}
          </PrimaryButton>
        </>
      )}
    </GlassCard>
  );
}

function CompleteLesson({ lessonId, onDone }: { lessonId: string; onDone: () => void }) {
  const { t } = useLang();
  const toast = useToast();
  const [busy, setBusy] = useState(false);

  async function complete() {
    setBusy(true);
    try {
      await api.post(`/courses/lessons/${lessonId}/complete`);
      toast.success(t.courses.lessonCompleted);
      onDone();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <PrimaryButton onClick={complete} loading={busy} className="mt-6 w-full py-3">
      {t.courses.markCompleted}
    </PrimaryButton>
  );
}

function HomeworkSection({
  homework,
  lessonId,
}: {
  homework: Homework | null | undefined;
  lessonId: string;
}) {
  const { t } = useLang();
  const toast = useToast();
  const [text, setText] = useState(homework?.submission_text ?? "");
  const [busy, setBusy] = useState(false);

  async function submit() {
    if (!text.trim()) return;
    setBusy(true);
    try {
      await api.post(`/courses/lessons/${lessonId}/homework`, { submission_text: text.trim() });
      toast.success(t.courses.homeworkSubmitted);
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <GlassCard className="mt-6 p-5">
      <div className="mb-3 flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 text-sm font-extrabold text-ink">
          <ClipboardList size={16} className="text-wine" /> {t.courses.homework}
        </div>
        {homework?.status && (
          <StatusPill tone={homework.status === "approved" ? "success" : homework.status === "rejected" ? "danger" : "warning"}>
            {t.courses.homeworkStatus}: {homework.status}
          </StatusPill>
        )}
      </div>

      {homework?.curator_feedback && (
        <div className="mb-3 rounded-2xl border border-wine/20 bg-wine-50 p-4 text-sm dark:bg-wine/15">
          <div className="mb-1 text-xs font-bold text-wine">{t.courses.homeworkStatus}</div>
          <p className="text-ink">{homework.curator_feedback}</p>
        </div>
      )}

      <GlassTextarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder={t.courses.homeworkTextPlaceholder}
        rows={4}
      />
      <div className="mt-3 flex items-center justify-between gap-3">
        <a href="/speech/voice" className="flex items-center gap-1.5 text-xs font-bold text-wine hover:underline">
          <Mic size={14} /> {t.courses.homeworkAudio}
        </a>
        <PrimaryButton onClick={submit} loading={busy} disabled={!text.trim()}>
          {t.courses.homeworkSubmit}
        </PrimaryButton>
      </div>
    </GlassCard>
  );
}
