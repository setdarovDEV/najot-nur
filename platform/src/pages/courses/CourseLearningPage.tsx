import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  Award,
  CheckCircle2,
  Circle,
  Clock,
  PlayCircle,
} from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, Spinner, StatusPill } from "../../components/glass";
import type { Course, CourseProgress } from "../../lib/types";

export function CourseLearningPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useLang();

  const courseQ = useQuery({
    queryKey: ["course", id],
    queryFn: async () => (await api.get<Course>(`/courses/${id}`)).data,
    enabled: !!id,
  });
  const progressQ = useQuery({
    queryKey: ["course-progress", id],
    queryFn: async () => (await api.get<CourseProgress>(`/courses/${id}/my-progress`)).data,
    enabled: !!id,
  });

  if (courseQ.isLoading || !courseQ.data) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  const course = courseQ.data;
  const progress = progressQ.data;
  const lessons = [...course.lessons].sort((a, b) => a.order_index - b.order_index);
  const pct = progress?.progress_pct ?? 0;
  const completedCount = progress?.lessons?.filter((l) => l.is_completed).length ?? 0;

  return (
    <div className="mx-auto max-w-3xl">
      <button
        type="button"
        onClick={() => navigate(`/courses/${id}`)}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-5">
        <h1 className="text-lg font-extrabold text-ink">{course.title}</h1>
        <div className="mt-3 flex items-center gap-3">
          <div className="h-2.5 flex-1 overflow-hidden rounded-full bg-wine/10">
            <div className="h-full rounded-full bg-wine" style={{ width: `${Math.min(pct, 100)}%` }} />
          </div>
          <span className="text-sm font-black text-wine">{pct}%</span>
        </div>
        <div className="mt-2 text-xs text-muted">
          {t.home.completedLessons}: {completedCount} / {lessons.length}
        </div>
      </GlassCard>

      <div className="mt-4 space-y-2">
        {lessons.map((lesson, i) => {
          const isCompleted = progress?.lessons?.find(
            (l) => l.lesson_id === lesson.id,
          )?.is_completed;
          return (
            <button
              key={lesson.id}
              type="button"
              onClick={() => navigate(`/courses/${id}/lessons/${lesson.id}`)}
              className="press w-full text-left"
            >
              <GlassCard className="flex items-center gap-4 p-4 transition hover:shadow-md">
                <div
                  className={`grid h-11 w-11 shrink-0 place-items-center rounded-2xl ${
                    isCompleted
                      ? "bg-success/15 text-success"
                      : "bg-wine-50 text-wine dark:bg-wine/20"
                  }`}
                >
                  {isCompleted ? <CheckCircle2 size={20} /> : <Circle size={18} />}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-[11px] font-black text-muted">
                      {t.courses.lesson} {i + 1}
                    </span>
                    {lesson.is_demo && <StatusPill tone="neutral">{t.common.demo}</StatusPill>}
                  </div>
                  <h3 className="mt-0.5 truncate text-sm font-extrabold text-ink">{lesson.title}</h3>
                  <div className="mt-1 flex items-center gap-2 text-[11px] text-muted">
                    <Clock size={12} />
                    {Math.round(lesson.duration_sec / 60)} {t.common.minutes}
                  </div>
                </div>
                <PlayCircle size={22} className="shrink-0 text-wine" />
              </GlassCard>
            </button>
          );
        })}
      </div>

      <GlassCard className="mt-6 flex items-center gap-4 p-5">
        <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
          <Award size={24} />
        </div>
        <div className="text-sm text-muted">
          <span className="font-bold text-ink">{t.courses.certificate}:</span>{" "}
          {t.courses.certificateSoon}
        </div>
      </GlassCard>
    </div>
  );
}
