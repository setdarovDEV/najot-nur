import { useMemo } from "react";
import { useLang } from "../../lib/i18n";
import { Link } from "react-router-dom";
import {
  Users,
  Mic,
  Headphones,
  ClipboardList,
  TrendingUp,
  BookOpen,
  ChevronRight,
} from "lucide-react";
import { useAuth } from "../../lib/auth";
import { useCuratorDashboard } from "../../lib/dashboard";
import { StatCard } from "./StatCard";
import { Panel } from "./Panel";
import { BarChart } from "./BarChart";
import { DashboardHero } from "./DashboardHero";
import { RecentHomeworks } from "./RecentHomeworks";
import { ScoreBadge } from "./ScoreBadge";
import { Reveal, StatusPill } from "../glass";
import type { ClientRow } from "../../lib/types";

export function CuratorDashboard() {
  const { user } = useAuth();
  const { t } = useLang();
  const d = useCuratorDashboard();
  const [statsQ, pendingQ, reviewedQ, coursesQ, leaderboardQ] = d;

  const pendingCount = pendingQ.data?.length ?? 0;
  const reviewedCount = reviewedQ.data?.length ?? 0;
  const totalCourses = coursesQ.data?.length ?? 0;

  // Score distribution from leaderboard (top 20 clients by score).
  const scoreDist = useMemo(() => {
    const buckets = [
      { label: "0–39 (past)", color: "#ef4444" },
      { label: "40–59 (o'rtacha)", color: "#f59e0b" },
      { label: "60–79 (yaxshi)", color: "#5BC2E7" },
      { label: "80–100 (a'lo)", color: "#22c55e" },
    ].map((b) => ({ ...b, value: 0 }));
    (leaderboardQ.data?.items ?? []).forEach((c: ClientRow) => {
      const s = c.last_speech_score;
      if (s == null) return;
      if (s < 40) buckets[0].value++;
      else if (s < 60) buckets[1].value++;
      else if (s < 80) buckets[2].value++;
      else buckets[3].value++;
    });
    return buckets;
  }, [leaderboardQ.data]);

  // Top performers by speech score.
  const topPerformers = useMemo(() => {
    const all = leaderboardQ.data?.items ?? [];
    return all
      .filter((c: ClientRow) => c.last_speech_score != null)
      .sort(
        (a: ClientRow, b: ClientRow) =>
          (b.last_speech_score ?? 0) - (a.last_speech_score ?? 0),
      )
      .slice(0, 5);
  }, [leaderboardQ.data]);

  return (
    <div className="space-y-4 p-4 sm:space-y-6 sm:p-5 md:p-8">
      <DashboardHero
        fullName={user?.full_name ?? null}
        statusLabel={t.dashboard.statusOk}
      />

      {/* ── KPI row ─────────────────────────────────────────── */}
      <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        <StatCard
          label={t.dashboard.statPendingHW}
          value={pendingCount}
          icon={ClipboardList}
          tone="orange"
          gradient
          loading={pendingQ.isLoading}
          hint={t.dashboard.statPendingHWHint}
        />
        <StatCard
          label={t.dashboard.statReviewed}
          value={reviewedCount}
          icon={TrendingUp}
          tone="sky"
          loading={reviewedQ.isLoading}
          hint={t.dashboard.statReviewedHint}
        />
        <StatCard
          label={t.dashboard.statStudents}
          value={statsQ.data?.users}
          icon={Users}
          tone="wine"
          loading={statsQ.isLoading}
          hint={t.dashboard.statStudentsHint}
        />
        <StatCard
          label={t.dashboard.statAnalyses}
          value={statsQ.data?.speech_analyses}
          icon={Mic}
          tone="wine"
          loading={statsQ.isLoading}
          hint={t.dashboard.statAnalysesHint}
        />
      </div>

      {/* ── Quick links row ───────────────────────────────── */}
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <QuickLink
          to="/homeworks"
          label={t.dashboard.quickNewTasks}
          value={pendingCount}
          tone="bg-orange/10 text-orange"
        />
        <QuickLink
          to="/audiobooks"
          label={t.dashboard.quickAudiobooks}
          value={statsQ.data?.audiobooks ?? 0}
          tone="bg-wine/10 text-wine dark:bg-wine/15 dark:text-wine-300"
        />
        <QuickLink
          to="/practicums"
          label={t.dashboard.quickPracticums}
          value="→"
          tone="bg-skyblue/10 text-skyblue"
          smallValue
        />
        <QuickLink
          to="/certificate-requests"
          label={t.dashboard.quickCertificates}
          value="→"
          tone="bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
          smallValue
        />
      </div>

      {/* ── Charts + recent homeworks ─────────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-5">
        <Panel
          title={t.dashboard.speechDist}
          subtitle={t.dashboard.speechDistStudentsSub}
          icon={<TrendingUp size={17} strokeWidth={1.75} />}
          className="lg:col-span-3"
        >
          {leaderboardQ.isLoading ? (
            <div className="h-40 animate-pulse rounded-xl bg-line/40" />
          ) : (
            <BarChart
              data={scoreDist}
              unit=""
              emptyText={t.dashboard.noRatedStudents}
            />
          )}
        </Panel>

        <RecentHomeworks
          rows={(pendingQ.data ?? []).slice(0, 5)}
          loading={pendingQ.isLoading}
          className="lg:col-span-2"
          asPanel
        />
      </div>

      {/* ── Performers + courses ──────────────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <Panel
          title={t.dashboard.topPerformers}
          subtitle={t.dashboard.topStudentsSub}
          icon={<TrendingUp size={17} strokeWidth={1.75} />}
          className="lg:col-span-2"
        >
          {leaderboardQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 animate-pulse rounded-xl bg-line/40" />
              ))}
            </div>
          ) : topPerformers.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              {t.dashboard.noRatedStudents}
            </p>
          ) : (
            <ol className="space-y-2">
              {topPerformers.map((c, idx) => (
                <li key={c.id}>
                  <Reveal
                    index={idx}
                    className="flex items-center gap-3 rounded-xl border border-line/60 p-3 transition hover:border-wine/30 hover:bg-wine-50/50 dark:hover:bg-wine-900/20"
                  >
                    <span
                      className={`grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-black ${
                        idx === 0
                          ? "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
                          : idx === 1
                            ? "bg-wine/10 text-wine dark:bg-wine/15 dark:text-wine-300"
                            : idx === 2
                              ? "bg-orange/15 text-orange dark:bg-orange/20 dark:text-orange"
                              : "bg-line/60 text-muted dark:bg-line/30"
                      }`}
                    >
                      {idx + 1}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-bold text-ink">
                        {c.full_name ?? t.dashboard.statStudents}
                      </div>
                      <div className="truncate text-xs text-muted">
                        {c.phone ?? c.email ?? "—"}
                      </div>
                    </div>
                    <ScoreBadge score={c.last_speech_score} />
                  </Reveal>
                </li>
              ))}
            </ol>
          )}
        </Panel>

        <Panel
          title={t.dashboard.courses}
          subtitle={t.dashboard.coursesSub(totalCourses)}
          icon={<BookOpen size={17} strokeWidth={1.75} />}
          action={
            <Link
              to="/video-lessons"
              className="press inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5 dark:text-wine-300"
            >
              {t.dashboard.coursesLink} <ChevronRight size={12} />
            </Link>
          }
        >
          {coursesQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-12 animate-pulse rounded-xl bg-line/40" />
              ))}
            </div>
          ) : coursesQ.data?.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              {t.dashboard.noCoursesYet}
            </p>
          ) : (
            <ul className="space-y-2">
              {coursesQ.data?.slice(0, 5).map((c, i) => (
                <li key={c.id}>
                  <Reveal
                    index={i}
                    className="flex items-center gap-3 rounded-xl p-2"
                  >
                    <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-wine/10 text-xs font-black text-wine dark:bg-wine/15 dark:text-wine-300">
                      <Headphones size={16} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-bold text-ink">
                        {c.title}
                      </div>
                      <div className="truncate text-xs text-muted">
                        {c.lesson_count} ta dars · {c.level}
                      </div>
                    </div>
                    <StatusPill tone={c.is_published ? "success" : "warning"} className="shrink-0">
                      {c.is_published ? t.videoLessons.published : t.videoLessons.draft}
                    </StatusPill>
                  </Reveal>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>
    </div>
  );
}

function QuickLink({
  to,
  label,
  value,
  tone,
  smallValue,
}: {
  to: string;
  label: string;
  value: number | string;
  tone: string;
  smallValue?: boolean;
}) {
  return (
    <Link
      to={to}
      className="group flex items-center gap-3 rounded-2xl border border-line bg-card p-4 transition hover:border-wine/30 hover:shadow-md hover:shadow-wine/5"
    >
      <div className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${tone}`}>
        <ChevronRight size={18} strokeWidth={2} className="rotate-180" />
      </div>
      <div className="min-w-0 flex-1">
        <div
          className={`truncate font-extrabold text-ink ${
            smallValue ? "text-base" : "text-xl"
          }`}
        >
          {value}
        </div>
        <div className="truncate text-xs text-muted">{label}</div>
      </div>
      <ChevronRight
        size={16}
        className="text-muted transition group-hover:translate-x-0.5 group-hover:text-wine dark:group-hover:text-wine-300"
      />
    </Link>
  );
}
