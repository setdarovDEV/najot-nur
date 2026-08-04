import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  BookOpen,
  CheckCircle2,
  Clock,
  Lock,
  Mic,
  PlayCircle,
  Video,
} from "lucide-react";
import { api, apiError, formatSum, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import { OrderModal } from "../../components/OrderModal";
import type { Course, CourseProgress, Lesson } from "../../lib/types";

export function CourseDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [orderOpen, setOrderOpen] = useState(false);
  const [enrolling, setEnrolling] = useState(false);

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

  const course = courseQ.data;
  const progress = progressQ.data;
  const cover = mediaUrl(course?.cover_url);
  const price = course?.price;
  const isFree = price === 0 || price === "0" || price === "0.00";

  async function enroll() {
    if (!id) return;
    setEnrolling(true);
    try {
      await api.post(`/courses/${id}/enroll`);
      toast.success(t.courses.enrolled);
      progressQ.refetch();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setEnrolling(false);
    }
  }

  if (courseQ.isLoading || !course) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  const enrolled = progress?.enrolled;
  const firstLesson = [...course.lessons].sort((a, b) => a.order_index - b.order_index)[0];
  const nextLesson = progress?.lessons?.find((l) => !l.is_completed);
  const continueLessonId = nextLesson?.lesson_id ?? firstLesson?.id;

  return (
    <div>
      <button
        type="button"
        onClick={() => navigate("/courses")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      {/* Hero */}
      <GlassCard className="overflow-hidden">
        <div className="relative h-52 sm:h-64">
          {cover ? (
            <img src={cover} alt={course.title} className="h-full w-full object-cover" />
          ) : (
            <div className="grid h-full w-full place-items-center bg-gradient-to-br from-wine/15 to-wine-deep/20">
              <BookOpen size={56} className="text-wine/30" />
            </div>
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
          <div className="absolute bottom-4 left-5 right-5 flex flex-wrap items-end justify-between gap-3">
            <div className="text-white">
              <StatusPill tone="neutral" className="bg-white/90 mb-2 text-wine">
                {t.courses.level}: {course.level}
              </StatusPill>
              <h1 className="text-xl font-black leading-tight sm:text-2xl">{course.title}</h1>
            </div>
          </div>
        </div>

        <div className="p-5">
          {course.description && (
            <p className="text-sm leading-relaxed text-muted">{course.description}</p>
          )}

          <div className="mt-4 flex flex-wrap items-center gap-2 text-xs text-muted">
            <span className="flex items-center gap-1"><BookOpen size={14} /> {t.courses.lessons(course.lessons.length)}</span>
            {firstLesson && (
              <span className="flex items-center gap-1"><Clock size={14} /> {Math.round(firstLesson.duration_sec / 60)} {t.common.minutes}</span>
            )}
          </div>

          <div className="mt-5 flex flex-wrap items-center gap-3">
            {enrolled ? (
              <>
                <PrimaryButton onClick={() => navigate(`/courses/${course.id}/learn`)}>
                  {continueLessonId ? t.courses.continueBtn : t.courses.enrolled}
                </PrimaryButton>
                <span className="flex items-center gap-1.5 text-xs font-bold text-success">
                  <CheckCircle2 size={15} /> {t.courses.enrolled}
                </span>
              </>
            ) : progress?.has_pending_order ? (
              <div className="flex items-center gap-2 rounded-2xl border border-warning/30 bg-warning/10 px-4 py-3 text-sm font-semibold text-warning">
                <Lock size={16} /> {t.courses.pendingOrder}
              </div>
            ) : isFree ? (
              <PrimaryButton onClick={enroll} loading={enrolling}>
                {t.courses.enroll}
              </PrimaryButton>
            ) : (
              <>
                <PrimaryButton onClick={() => setOrderOpen(true)}>
                  {t.courses.buy} · {formatSum(price)} so'm
                </PrimaryButton>
                <span className="text-sm font-black text-ink">{formatSum(price)} so'm</span>
              </>
            )}
          </div>
        </div>
      </GlassCard>

      {/* Lesson list */}
      <h2 className="mb-3 mt-8 text-sm font-extrabold uppercase tracking-wide text-muted">
        {t.courses.courseContent}
      </h2>
      <div className="space-y-2">
        {[...course.lessons]
          .sort((a, b) => a.order_index - b.order_index)
          .map((lesson, i) => (
            <LessonRow
              key={lesson.id}
              index={i}
              lesson={lesson}
              enrolled={!!enrolled}
              onClick={() => navigate(`/courses/${course.id}/lessons/${lesson.id}`)}
            />
          ))}
      </div>

      {courseQ.data && (
        <OrderModal
          open={orderOpen}
          onClose={() => setOrderOpen(false)}
          purpose="course"
          amount={Number(price)}
          courseId={course.id}
          onSuccess={() => progressQ.refetch()}
        />
      )}
    </div>
  );
}

function LessonRow({
  lesson,
  index,
  enrolled,
  onClick,
}: {
  lesson: Lesson;
  index: number;
  enrolled: boolean;
  onClick: () => void;
}) {
  const { t } = useLang();
  const locked = !enrolled && !lesson.is_demo;
  const Icon = lesson.is_voice_exercise ? Mic : Video;

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={locked}
      className="press w-full text-left"
    >
      <GlassCard className={`flex items-center gap-4 p-4 ${locked ? "opacity-55" : "hover:shadow-md"}`}>
        <div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
          {locked ? <Lock size={18} /> : <Icon size={18} />}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="text-[11px] font-black text-muted">
              {t.courses.lesson} {index + 1}
            </span>
            {lesson.is_demo && <StatusPill tone="neutral">{t.common.demo}</StatusPill>}
            {lesson.is_voice_exercise && <StatusPill tone="warning">{t.courses.voiceExercise}</StatusPill>}
          </div>
          <h3 className="mt-0.5 truncate text-sm font-extrabold text-ink">{lesson.title}</h3>
          <div className="mt-1 flex items-center gap-2 text-[11px] text-muted">
            <Clock size={12} />
            {Math.round(lesson.duration_sec / 60)} {t.common.minutes}
          </div>
        </div>
        {!locked && <PlayCircle size={22} className="shrink-0 text-wine" />}
      </GlassCard>
    </button>
  );
}
