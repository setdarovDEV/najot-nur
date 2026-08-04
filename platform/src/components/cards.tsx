import { Link } from "react-router-dom";
import { BookOpen, Headphones, Mic, ListChecks } from "lucide-react";
import type { Audiobook, Course, Practicum, Quiz } from "../lib/types";
import { mediaUrl, formatSum } from "../lib/api";
import { useLang } from "../lib/i18n";
import { GlassCard, StatusPill } from "./glass";

export function CourseCard({
  course,
  progressPct,
  className = "",
}: {
  course: Course;
  progressPct?: number | null;
  className?: string;
}) {
  const { t } = useLang();
  const cover = mediaUrl(course.cover_url);
  const price = course.price;
  const isFree = price === 0 || price === "0" || price === "0.00";

  return (
    <Link to={`/courses/${course.id}`} className={`block ${className}`}>
      <GlassCard className="press h-full overflow-hidden transition hover:-translate-y-0.5 hover:shadow-lg">
        <div className="relative h-36 overflow-hidden bg-wine-deep/10">
          {cover ? (
            <img src={cover} alt={course.title} className="h-full w-full object-cover" />
          ) : (
            <div className="grid h-full w-full place-items-center">
              <BookOpen size={36} className="text-wine/30" />
            </div>
          )}
          <div className="absolute left-3 top-3">
            <StatusPill tone="neutral" className="bg-white/90 backdrop-blur">
              {t.courses.level}: {course.level}
            </StatusPill>
          </div>
          {progressPct != null && progressPct > 0 && (
            <div className="absolute inset-x-0 bottom-0 h-1.5 bg-white/30">
              <div
                className="h-full bg-wine"
                style={{ width: `${Math.min(progressPct, 100)}%` }}
              />
            </div>
          )}
        </div>
        <div className="p-4">
          <h3 className="line-clamp-2 text-sm font-extrabold leading-snug text-ink">
            {course.title}
          </h3>
          <div className="mt-2 flex items-center justify-between">
            <span className="text-xs text-muted">{t.courses.lessons(course.lessons.length)}</span>
            {progressPct != null && progressPct > 0 ? (
              <span className="text-xs font-bold text-wine">{progressPct}%</span>
            ) : isFree ? (
              <span className="text-xs font-bold text-success">{t.courses.priceFree}</span>
            ) : (
              <span className="text-xs font-bold text-ink">{formatSum(price)} so'm</span>
            )}
          </div>
        </div>
      </GlassCard>
    </Link>
  );
}

export function AudiobookCard({
  book,
  className = "",
}: {
  book: Audiobook;
  className?: string;
}) {
  const { t } = useLang();
  const cover = mediaUrl(book.cover_url);
  const isFree = book.is_free;

  return (
    <Link to={`/audiobooks/${book.id}`} className={`block ${className}`}>
      <GlassCard className="press flex h-full items-center gap-4 overflow-hidden p-4 transition hover:-translate-y-0.5 hover:shadow-lg">
        <div className="grid h-20 w-20 shrink-0 place-items-center overflow-hidden rounded-2xl bg-wine-deep/10">
          {cover ? (
            <img src={cover} alt={book.title} className="h-full w-full object-cover" />
          ) : (
            <Headphones size={28} className="text-wine/30" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="line-clamp-2 text-sm font-extrabold leading-snug text-ink">
            {book.title}
          </h3>
          {book.author && (
            <p className="mt-0.5 truncate text-xs text-muted">
              {t.audiobooks.by}: {book.author}
            </p>
          )}
          <div className="mt-2 flex items-center gap-2">
            <span className="text-xs text-muted">{t.audiobooks.pages(book.total_pages)}</span>
            {isFree ? (
              <StatusPill tone="success">{t.audiobooks.freeBook}</StatusPill>
            ) : (
              <span className="text-xs font-bold text-ink">{formatSum(book.price)} so'm</span>
            )}
          </div>
        </div>
      </GlassCard>
    </Link>
  );
}

export function QuizCard({
  quiz,
  className = "",
}: {
  quiz: Quiz;
  className?: string;
}) {
  const { t } = useLang();
  return (
    <Link to={`/quizzes/${quiz.id}`} className={`block ${className}`}>
      <GlassCard className="press h-full p-4 transition hover:-translate-y-0.5 hover:shadow-lg">
        <div className="flex items-start justify-between gap-2">
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
            <ListChecks size={20} />
          </div>
          <StatusPill tone="neutral">{quiz.difficulty}</StatusPill>
        </div>
        <h3 className="mt-3 line-clamp-2 text-sm font-extrabold leading-snug text-ink">
          {quiz.title}
        </h3>
        <div className="mt-2 text-xs text-muted">{t.quizzes.questions(quiz.question_count)}</div>
      </GlassCard>
    </Link>
  );
}

export function PracticumCard({
  practicum,
  className = "",
}: {
  practicum: Practicum;
  className?: string;
}) {
  const { t } = useLang();
  const isFree = practicum.is_free;
  return (
    <Link to={`/practicums/${practicum.id}`} className={`block ${className}`}>
      <GlassCard className="press h-full p-4 transition hover:-translate-y-0.5 hover:shadow-lg">
        <div className="flex items-start justify-between gap-2">
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
            <Mic size={20} />
          </div>
          {isFree ? (
            <StatusPill tone="success">{t.common.free}</StatusPill>
          ) : (
            <span className="text-xs font-bold text-ink">{formatSum(practicum.price)} so'm</span>
          )}
        </div>
        <h3 className="mt-3 line-clamp-2 text-sm font-extrabold leading-snug text-ink">
          {practicum.title}
        </h3>
        {practicum.category && (
          <div className="mt-2 text-xs text-muted">
            {t.practicums.category}: {practicum.category}
          </div>
        )}
      </GlassCard>
    </Link>
  );
}
