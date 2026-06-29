import { useMemo, useState } from "react";
import { useLang } from "../../lib/i18n";
import { Link } from "react-router-dom";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ClipboardList,
  Headphones,
  Video,
  CheckCircle2,
  ChevronRight,
  Sparkles,
  Send,
  Clock,
  TrendingUp,
  Award,
} from "lucide-react";
import { useAuth } from "../../lib/auth";
import { useCuratorDashboard } from "../../lib/dashboard";
import { api, apiError } from "../../lib/api";
import { StatCard } from "./StatCard";
import { Panel } from "./Panel";
import { BarChart } from "./BarChart";
import { DashboardHero } from "./DashboardHero";
import { ScoreBadge } from "./ScoreBadge";
import { SkeletonList } from "./RecentClients";
import type { ClientRow, Homework } from "../../lib/types";

export function CuratorDashboard() {
  const { user } = useAuth();
  const { t } = useLang();
  const qc = useQueryClient();
  const d = useCuratorDashboard();
  const [statsQ, pendingQ, reviewedQ, coursesQ, leaderQ] = d;

  const pending = pendingQ.data ?? [];
  const reviewed = reviewedQ.data ?? [];
  const reviewedThisWeek = useMemo(() => {
    const since = Date.now() - 7 * 24 * 60 * 60 * 1000;
    return reviewed.filter(
      (h) => h.reviewed_at && new Date(h.reviewed_at).getTime() >= since,
    ).length;
  }, [reviewed]);

  const audiobooksCount = statsQ.data?.audiobooks ?? 0;
  const pendingCount = statsQ.data?.pending_homeworks ?? 0;
  const coursesCount = coursesQ.data?.length ?? 0;

  const topStudents = useMemo(() => {
    const all = leaderQ.data?.items ?? [];
    return all
      .filter((c: ClientRow) => c.last_speech_score != null)
      .sort(
        (a: ClientRow, b: ClientRow) =>
          (b.last_speech_score ?? 0) - (a.last_speech_score ?? 0),
      )
      .slice(0, 5);
  }, [leaderQ.data]);

  const scoreDist = useMemo(() => {
    const buckets = [
      { label: "0–39", color: "#ef4444" },
      { label: "40–59", color: "#f59e0b" },
      { label: "60–79", color: "#5BC2E7" },
      { label: "80–100", color: "#22c55e" },
    ].map((b) => ({ ...b, value: 0 }));
    (leaderQ.data?.items ?? []).forEach((c: ClientRow) => {
      const s = c.last_speech_score;
      if (s == null) return;
      if (s < 40) buckets[0].value++;
      else if (s < 60) buckets[1].value++;
      else if (s < 80) buckets[2].value++;
      else buckets[3].value++;
    });
    return buckets;
  }, [leaderQ.data]);

  return (
    <div className="space-y-6 p-5 md:p-8">
      <DashboardHero
        fullName={user?.full_name ?? null}
        role="curator"
        statusLabel={
          pendingCount === 0
            ? t.dashboard.statusOk
            : `${pendingCount} ${t.homeworks.new_}`
        }
        statusTone={pendingCount === 0 ? "green" : "amber"}
      />

      {/* ── KPI row ─────────────────────────────────────────── */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          label="Tekshirilmagan vazifalar"
          value={pendingCount}
          icon={ClipboardList}
          tone="orange"
          gradient
          loading={statsQ.isLoading}
          hint="Sizning navbatingizdagi"
        />
        <StatCard
          label="Bu hafta tekshirilgan"
          value={reviewedThisWeek}
          icon={CheckCircle2}
          tone="sky"
          loading={statsQ.isLoading}
          hint="So'nggi 7 kun ichida"
        />
        <StatCard
          label="Audiokitoblar"
          value={audiobooksCount}
          icon={Headphones}
          tone="wine"
          loading={statsQ.isLoading}
          hint="Platformadagi audio kontent"
        />
        <StatCard
          label="Video kurslar"
          value={coursesCount}
          icon={Video}
          tone="ink"
          loading={statsQ.isLoading}
          hint="Boshqariladigan kurslar"
        />
      </div>

      {/* ── Pending vs reviewed quick action ──────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <Panel
          title="Tekshirish navbatida"
          subtitle="Eng so'nggi yuborilgan vazifalar"
          icon={<Clock size={17} strokeWidth={1.75} />}
          className="lg:col-span-2"
          action={
            <Link
              to="/homeworks"
              className="inline-flex items-center gap-1 rounded-lg bg-wine px-3 py-1.5 text-xs font-bold text-white hover:bg-wine-dark"
            >
              <Send size={12} />
              Baholash sahifasi
            </Link>
          }
        >
          {pendingQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, i) => (
                <div
                  key={i}
                  className="h-20 animate-pulse rounded-xl bg-line/40"
                />
              ))}
            </div>
          ) : pending.length === 0 ? (
            <div className="rounded-xl border border-dashed border-line py-10 text-center">
              <div className="mx-auto mb-2 grid h-12 w-12 place-items-center rounded-full bg-green-100 text-green-600">
                <CheckCircle2 size={22} />
              </div>
              <p className="text-sm font-bold text-ink">
                Ajoyib! Hozircha tekshirilmagan vazifalar yo'q 🎉
              </p>
              <p className="mt-1 text-xs text-muted">
                Yangi vazifalar kelganda shu yerda ko'rinadi
              </p>
            </div>
          ) : (
            <ul className="space-y-3">
              {pending.slice(0, 4).map((hw) => (
                <PendingHomeworkItem key={hw.id} hw={hw} qc={qc} />
              ))}
            </ul>
          )}
        </Panel>

        <Panel
          title="Tezkor havolalar"
          subtitle="Kontent bo'limlari"
          icon={<Sparkles size={17} strokeWidth={1.75} />}
        >
          <div className="space-y-2">
            <QuickLink
              to="/homeworks"
              label="Barcha vazifalar"
              hint="Yangi va tekshirilgan"
              icon={ClipboardList}
              tone="bg-orange/10 text-orange"
            />
            <QuickLink
              to="/audiobooks"
              label="Audiokitoblar"
              hint="Yuklash va tahrirlash"
              icon={Headphones}
              tone="bg-wine/10 text-wine"
            />
            <QuickLink
              to="/video-lessons"
              label="Video darsliklar"
              hint="Kurs va darslarni boshqarish"
              icon={Video}
              tone="bg-skyblue/15 text-skyblue"
            />
          </div>
        </Panel>
      </div>

      {/* ── Recent graded & top students ─────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
        <Panel
          title="So'nggi tekshirilganlar"
          subtitle="Siz tomonidan baholangan vazifalar"
          icon={<CheckCircle2 size={17} strokeWidth={1.75} />}
        >
          {reviewedQ.isLoading ? (
            <SkeletonList rows={4} />
          ) : reviewed.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              Hali tekshirilgan vazifalar yo'q
            </p>
          ) : (
            <ul className="space-y-2">
              {reviewed.slice(0, 5).map((hw) => (
                <li
                  key={hw.id}
                  className="flex items-center gap-3 rounded-xl border border-line/60 p-3"
                >
                  <div className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-green-100 text-green-700">
                    <CheckCircle2 size={16} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="line-clamp-1 text-sm font-semibold text-ink">
                      {hw.submission_text ?? "Matnsiz yuborilgan"}
                    </p>
                    <p className="text-xs text-muted">
                      {hw.reviewed_at
                        ? new Date(hw.reviewed_at).toLocaleString("uz-UZ", {
                            day: "2-digit",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })
                        : "—"}
                    </p>
                  </div>
                  <ScoreBadge score={hw.curator_score} />
                </li>
              ))}
            </ul>
          )}
        </Panel>

        <Panel
          title="Eng yaxshi o'quvchilar"
          subtitle="Yuqori nutq baliga ega mijozlar"
          icon={<Award size={17} strokeWidth={1.75} />}
        >
          {leaderQ.isLoading ? (
            <SkeletonList rows={5} />
          ) : topStudents.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              Hali natijalar yo'q
            </p>
          ) : (
            <ol className="space-y-2">
              {topStudents.map((c, idx) => (
                <li key={c.id}>
                  <Link
                    to={`/clients/${c.id}`}
                    className="flex items-center gap-3 rounded-xl border border-line/60 p-3 transition hover:border-wine/30 hover:bg-wine-50/50"
                  >
                    <span
                      className={`grid h-7 w-7 shrink-0 place-items-center rounded-lg text-xs font-black ${
                        idx === 0
                          ? "bg-amber-100 text-amber-700"
                          : idx === 1
                            ? "bg-wine/10 text-wine"
                            : idx === 2
                              ? "bg-orange/15 text-orange"
                              : "bg-line/60 text-muted"
                      }`}
                    >
                      {idx + 1}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-sm font-bold text-ink">
                        {c.full_name ?? "Ismsiz mijoz"}
                      </div>
                      <div className="truncate text-xs text-muted">
                        {c.phone ?? c.email ?? "—"}
                      </div>
                    </div>
                    <ScoreBadge score={c.last_speech_score} />
                  </Link>
                </li>
              ))}
            </ol>
          )}
        </Panel>
      </div>

      {/* ── Score distribution ──────────────────────────── */}
      <Panel
        title="O'quvchilar bahosi taqsimoti"
        subtitle="Mijozlarning so'nggi nutq tahlili natijalari"
        icon={<TrendingUp size={17} strokeWidth={1.75} />}
      >
        {leaderQ.isLoading ? (
          <div className="h-40 animate-pulse rounded-xl bg-line/40" />
        ) : (
          <BarChart
            data={scoreDist}
            emptyText="Hali baholangan mijozlar yo'q"
          />
        )}
      </Panel>
    </div>
  );
}

// ─── PendingHomeworkItem (inline quick-grade) ─────────────────────────────

function PendingHomeworkItem({
  hw,
  qc,
}: {
  hw: Homework;
  qc: ReturnType<typeof useQueryClient>;
}) {
  const [open, setOpen] = useState(false);
  const [score, setScore] = useState(80);
  const [feedback, setFeedback] = useState("");

  const grade = useMutation({
    mutationFn: () =>
      api.post(`/admin/homeworks/${hw.id}/grade`, { score, feedback }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "dashboard-homeworks"] });
      qc.invalidateQueries({ queryKey: ["admin", "stats"] });
      setOpen(false);
      setFeedback("");
    },
  });

  return (
    <li className="rounded-xl border border-line/70 p-3.5 transition hover:border-wine/30">
      <div className="flex items-start justify-between gap-3">
        <p className="line-clamp-2 text-sm text-ink">
          {hw.submission_text ?? hw.submission_url ?? "Matn yuborilmagan"}
        </p>
        <span className="shrink-0 rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-700">
          Yangi
        </span>
      </div>
      <div className="mt-2 flex items-center justify-between text-[11px] text-muted">
        <span>
          {new Date(hw.created_at).toLocaleString("uz-UZ", {
            day: "2-digit",
            month: "short",
            hour: "2-digit",
            minute: "2-digit",
          })}
        </span>
        {!open ? (
          <button
            onClick={() => setOpen(true)}
            className="font-bold text-wine hover:underline"
          >
            Tezkor baholash
          </button>
        ) : null}
      </div>

      {open && (
        <div className="mt-3 space-y-2 border-t border-line/60 pt-3">
          <div className="flex flex-wrap items-end gap-2">
            <label className="text-xs">
              <span className="mb-1 block font-semibold text-ink">Ball</span>
              <input
                type="number"
                min={0}
                max={100}
                value={score}
                onChange={(e) => setScore(Number(e.target.value))}
                className="w-20 rounded-lg border border-line px-2.5 py-1.5 text-sm outline-none focus:border-wine"
              />
            </label>
            <label className="min-w-0 flex-1 text-xs">
              <span className="mb-1 block font-semibold text-ink">Izoh</span>
              <input
                value={feedback}
                onChange={(e) => setFeedback(e.target.value)}
                placeholder="Fikr-mulohaza..."
                className="w-full rounded-lg border border-line px-2.5 py-1.5 text-sm outline-none focus:border-wine"
              />
            </label>
          </div>
          {grade.isError && (
            <p className="text-xs text-red-600">{apiError(grade.error)}</p>
          )}
          <div className="flex justify-end gap-2">
            <button
              onClick={() => setOpen(false)}
              className="rounded-lg border border-line px-3 py-1.5 text-xs font-semibold text-muted hover:bg-line/40"
            >
              Bekor
            </button>
            <button
              onClick={() => grade.mutate()}
              disabled={grade.isPending}
              className="inline-flex items-center gap-1.5 rounded-lg bg-wine px-3.5 py-1.5 text-xs font-bold text-white hover:bg-wine-dark disabled:opacity-50"
            >
              <CheckCircle2 size={12} />
              {grade.isPending ? "Saqlanmoqda…" : "Saqlash"}
            </button>
          </div>
        </div>
      )}
    </li>
  );
}

// ─── QuickLink ─────────────────────────────────────────────────────────────

function QuickLink({
  to,
  label,
  hint,
  icon: Icon,
  tone,
}: {
  to: string;
  label: string;
  hint: string;
  icon: typeof Headphones;
  tone: string;
}) {
  return (
    <Link
      to={to}
      className="group flex items-center gap-3 rounded-xl border border-line/70 p-3 transition hover:border-wine/30 hover:bg-wine-50/50"
    >
      <div
        className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${tone}`}
      >
        <Icon size={18} strokeWidth={1.75} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-bold text-ink">{label}</div>
        <div className="truncate text-xs text-muted">{hint}</div>
      </div>
      <ChevronRight
        size={14}
        className="text-muted transition group-hover:translate-x-0.5 group-hover:text-wine"
      />
    </Link>
  );
}
