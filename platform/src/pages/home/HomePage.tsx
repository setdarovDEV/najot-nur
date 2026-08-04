import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Mic, AudioLines, Eye, BookOpenText, ArrowRight, TrendingUp } from "lucide-react";
import { api } from "../../lib/api";
import { useAuth } from "../../lib/auth";
import { useLang } from "../../lib/i18n";
import { GlassCard, Reveal, Spinner, StatusPill } from "../../components/glass";
import { AudiobookCard, CourseCard } from "../../components/cards";
import type { Audiobook, Course, Enrollment, Quiz } from "../../lib/types";

interface EnrollmentWithCourse extends Enrollment {
  course?: Course;
}

export function HomePage() {
  const { user } = useAuth();
  const { t } = useLang();

  const coursesQ = useQuery({
    queryKey: ["courses"],
    queryFn: async () => (await api.get<Course[]>("/courses")).data,
  });
  const enrollmentsQ = useQuery({
    queryKey: ["enrollments"],
    queryFn: async () => (await api.get<Enrollment[]>("/courses/me/enrollments")).data,
  });
  const audiobooksQ = useQuery({
    queryKey: ["audiobooks"],
    queryFn: async () => (await api.get<Audiobook[]>("/audiobooks", { params: { free_only: true } })).data,
  });
  const quizzesQ = useQuery({
    queryKey: ["quizzes"],
    queryFn: async () => (await api.get<Quiz[]>("/quizzes")).data,
  });

  const courses = coursesQ.data ?? [];
  const enrollments = enrollmentsQ.data ?? [];
  const myCourses: EnrollmentWithCourse[] = enrollments
    .map((e) => ({
      ...e,
      course: courses.find((c) => c.id === e.course_id),
    }))
    .filter((e) => e.course);

  const name = user?.full_name ?? "";

  const quickActions = [
    { to: "/speech/talk", icon: Mic, label: t.home.freeTalk, desc: t.speech.talkDescription },
    { to: "/speech/voice", icon: AudioLines, label: t.home.voiceTest, desc: t.speech.voiceDescription },
    { to: "/observation", icon: Eye, label: t.home.observationTest, desc: t.observation.subtitle },
    { to: "/speech/practice", icon: BookOpenText, label: t.speech.practice, desc: t.speech.practiceDescription },
  ];

  return (
    <div className="space-y-8">
      {/* Greeting */}
      <Reveal>
        <div className="relative overflow-hidden rounded-[28px] bg-gradient-to-br from-wine via-wine-dark to-wine-deep p-6 text-white shadow-xl shadow-wine-deep/20 sm:p-8">
          <div
            className="pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full opacity-30"
            style={{ background: "radial-gradient(circle, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0) 70%)" }}
          />
          <h1 className="text-xl font-black leading-tight sm:text-2xl">
            {name ? t.home.greeting(name) : t.home.guestGreeting}
          </h1>
          <p className="mt-1.5 text-sm text-white/70">{t.home.welcomeBack}</p>
        </div>
      </Reveal>

      {/* Quick actions */}
      <Reveal index={1}>
        <div>
          <h2 className="mb-3 text-sm font-extrabold uppercase tracking-wide text-muted">
            {t.home.quickActions}
          </h2>
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            {quickActions.map((a) => (
              <Link key={a.to} to={a.to}>
                <GlassCard className="press h-full p-4 transition hover:-translate-y-0.5 hover:shadow-lg">
                  <div className="grid h-10 w-10 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
                    <a.icon size={20} />
                  </div>
                  <div className="mt-3 text-sm font-extrabold text-ink">{a.label}</div>
                  <p className="mt-1 line-clamp-2 text-[11px] leading-relaxed text-muted">
                    {a.desc}
                  </p>
                </GlassCard>
              </Link>
            ))}
          </div>
        </div>
      </Reveal>

      {/* My courses */}
      <Reveal index={2}>
        <SectionHeader
          title={t.home.myCourses}
          link={enrollments.length ? "/courses" : undefined}
          linkLabel={t.home.exploreAll}
        />
        {enrollmentsQ.isLoading ? (
          <div className="py-8"><Spinner /></div>
        ) : myCourses.length === 0 ? (
          <GlassCard className="p-5 text-center">
            <p className="text-sm text-muted">{t.home.noEnrollments}</p>
            <Link to="/courses" className="mt-3 inline-block text-sm font-bold text-wine hover:underline">
              {t.home.exploreAll} →
            </Link>
          </GlassCard>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {myCourses.map((e) => (
              <CourseCard key={e.id} course={e.course!} progressPct={e.progress_pct} />
            ))}
          </div>
        )}
      </Reveal>

      {/* Popular courses */}
      <Reveal index={3}>
        <SectionHeader title={t.home.popularCourses} link="/courses" linkLabel={t.home.exploreAll} />
        {coursesQ.isLoading ? (
          <div className="py-8"><Spinner /></div>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {courses.slice(0, 6).map((c) => (
              <CourseCard key={c.id} course={c} />
            ))}
          </div>
        )}
      </Reveal>

      {/* Audiobooks */}
      <Reveal index={4}>
        <SectionHeader title={t.home.popularAudiobooks} link="/audiobooks" linkLabel={t.home.exploreAll} />
        {audiobooksQ.isLoading ? (
          <div className="py-8"><Spinner /></div>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {audiobooksQ.data?.slice(0, 6).map((b) => (
              <AudiobookCard key={b.id} book={b} />
            ))}
          </div>
        )}
      </Reveal>

      {/* New quizzes */}
      <Reveal index={5}>
        <SectionHeader title={t.home.newTests} link="/quizzes" linkLabel={t.home.exploreAll} />
        {quizzesQ.isLoading ? (
          <div className="py-8"><Spinner /></div>
        ) : quizzesQ.data?.length ? (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {quizzesQ.data.slice(0, 3).map((q) => (
              <Link key={q.id} to={`/quizzes/${q.id}`}>
                <GlassCard className="press flex h-full items-center gap-3 p-4 transition hover:-translate-y-0.5 hover:shadow-lg">
                  <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
                    <TrendingUp size={20} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3 className="line-clamp-1 text-sm font-extrabold text-ink">{q.title}</h3>
                    <div className="mt-1 flex items-center gap-2 text-xs text-muted">
                      <StatusPill tone="neutral">{q.difficulty}</StatusPill>
                      {t.quizzes.questions(q.question_count)}
                    </div>
                  </div>
                  <ArrowRight size={16} className="shrink-0 text-muted" />
                </GlassCard>
              </Link>
            ))}
          </div>
        ) : (
          <GlassCard className="p-5 text-center text-sm text-muted">{t.quizzes.noQuizzes}</GlassCard>
        )}
      </Reveal>
    </div>
  );
}

function SectionHeader({
  title,
  link,
  linkLabel,
}: {
  title: string;
  link?: string;
  linkLabel?: string;
}) {
  return (
    <div className="mb-3 flex items-center justify-between gap-2">
      <h2 className="text-sm font-extrabold uppercase tracking-wide text-muted">{title}</h2>
      {link && linkLabel && (
        <Link to={link} className="flex shrink-0 items-center gap-1 text-xs font-bold text-wine hover:underline">
          {linkLabel} <ArrowRight size={13} />
        </Link>
      )}
    </div>
  );
}
