import { useMemo } from "react";
import { useLang } from "../../lib/i18n";
import { Link } from "react-router-dom";
import {
  Users,
  Mic,
  Headphones,
  ClipboardList,
  CreditCard,
  Bell,
  TrendingUp,
  BookOpen,
  GraduationCap,
  ChevronRight,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "../../lib/auth";
import { useAdminDashboard } from "../../lib/dashboard";
import { StatCard } from "./StatCard";
import { Panel } from "./Panel";
import { RingChart } from "./RingChart";
import { BarChart } from "./BarChart";
import { DashboardHero } from "./DashboardHero";
import { RecentClients, SkeletonList } from "./RecentClients";
import { RecentHomeworks } from "./RecentHomeworks";
import { RecentPayments } from "./RecentPayments";
import { ScoreBadge } from "./ScoreBadge";
import type { ClientRow, Homework, Payment, PaymentStatus } from "../../lib/types";

const PAYMENT_COLORS: Record<PaymentStatus, string> = {
  paid: "#22c55e",
  pending: "#f59e0b",
  failed: "#ef4444",
  refunded: "#9ca3af",
};

export function AdminDashboard() {
  const { user } = useAuth();
  const { t } = useLang();
  const d = useAdminDashboard();
  const [statsQ, clientsQ, pendingQ, paymentsQ, pushQ, coursesQ, curatorsQ] = d;

  const totalCourses = coursesQ.data?.length ?? 0;
  const totalCurators = curatorsQ.data?.length ?? 0;
  const totalPush = pushQ.data?.length ?? 0;

  // Speech score distribution from latest scores of recent clients.
  const scoreDist = useMemo(() => {
    const buckets = [
      { label: "0–39 (past)", color: "#ef4444" },
      { label: "40–59 (o'rtacha)", color: "#f59e0b" },
      { label: "60–79 (yaxshi)", color: "#5BC2E7" },
      { label: "80–100 (a'lo)", color: "#22c55e" },
    ].map((b) => ({ ...b, value: 0 }));
    (clientsQ.data?.items ?? []).forEach((c: ClientRow) => {
      const s = c.last_speech_score;
      if (s == null) return;
      if (s < 40) buckets[0].value++;
      else if (s < 60) buckets[1].value++;
      else if (s < 80) buckets[2].value++;
      else buckets[3].value++;
    });
    return buckets;
  }, [clientsQ.data]);

  // Payment status breakdown.
  const paymentRings = useMemo(() => {
    const counts: Record<PaymentStatus, number> = {
      paid: 0,
      pending: 0,
      failed: 0,
      refunded: 0,
    };
    (paymentsQ.data?.items ?? []).forEach((p: Payment) => {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    });
    return (Object.keys(counts) as PaymentStatus[]).map((k) => ({
      label:
        k === "paid"
          ? "To'langan"
          : k === "pending"
            ? "Kutilmoqda"
            : k === "failed"
              ? "Xato"
              : "Qaytarilgan",
      value: counts[k],
      color: PAYMENT_COLORS[k],
    }));
  }, [paymentsQ.data]);

  // Total paid amount.
  const totalPaid = useMemo(
    () =>
      (paymentsQ.data?.items ?? [])
        .filter((p: Payment) => p.status === "paid")
        .reduce((s: number, p: Payment) => s + parseFloat(p.amount || "0"), 0)
        .toLocaleString("uz-UZ") + " UZS",
    [paymentsQ.data],
  );

  // Top performers by speech score.
  const topPerformers = useMemo(() => {
    const all = clientsQ.data?.items ?? [];
    return all
      .filter((c: ClientRow) => c.last_speech_score != null)
      .sort(
        (a: ClientRow, b: ClientRow) =>
          (b.last_speech_score ?? 0) - (a.last_speech_score ?? 0),
      )
      .slice(0, 5);
  }, [clientsQ.data]);

  const isLoading =
    statsQ.isLoading ||
    clientsQ.isLoading ||
    pendingQ.isLoading ||
    paymentsQ.isLoading;

  return (
    <div className="space-y-6 p-5 md:p-8">
      <DashboardHero
        fullName={user?.full_name ?? null}
        role="admin"
        statusLabel={t.dashboard.statusOk}
      />

      {/* ── KPI row ─────────────────────────────────────────── */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          label="Mijozlar"
          value={statsQ.data?.users}
          icon={Users}
          tone="wine"
          gradient
          loading={statsQ.isLoading}
          hint="Barcha ro'yxatdan o'tganlar"
        />
        <StatCard
          label="Nutq tahlillari"
          value={statsQ.data?.speech_analyses}
          icon={Mic}
          tone="sky"
          loading={statsQ.isLoading}
          hint="AI tomonidan tahlil qilingan"
        />
        <StatCard
          label="Tekshirilmagan vazifalar"
          value={statsQ.data?.pending_homeworks}
          icon={ClipboardList}
          tone="orange"
          loading={statsQ.isLoading}
          hint="Kuratorlar ko'rib chiqishi kerak"
        />
        <StatCard
          label="Audiokitoblar"
          value={statsQ.data?.audiobooks}
          icon={Headphones}
          tone="wine"
          loading={statsQ.isLoading}
          hint="Platformadagi audio kontent"
        />
      </div>

      {/* ── Quick links row ───────────────────────────────── */}
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <QuickLink
          to="/curators"
          label="Kuratorlar"
          value={totalCurators}
          icon={GraduationCap}
          tone="bg-skyblue/10 text-skyblue dark:bg-skyblue/20 dark:text-skyblue"
        />
        <QuickLink
          to="/courses"
          label="Video kurslar"
          value={totalCourses}
          icon={BookOpen}
          tone="bg-wine/10 text-wine dark:bg-wine/15 dark:text-wine-300"
        />
        <QuickLink
          to="/payments"
          label="Tushum"
          value={totalPaid}
          icon={CreditCard}
          tone="bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
          smallValue
        />
        <QuickLink
          to="/notifications"
          label="Push xabarlar"
          value={totalPush}
          icon={Bell}
          tone="bg-orange/10 text-orange dark:bg-orange/15 dark:text-orange"
        />
      </div>

      {/* ── Charts row ────────────────────────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-5">
        <Panel
          title="To'lov holati"
          subtitle="So'nggi 8 ta tranzaksiya taqsimoti"
          icon={<CreditCard size={17} strokeWidth={1.75} />}
          className="lg:col-span-2"
        >
          {paymentsQ.isLoading ? (
            <div className="h-40 animate-pulse rounded-xl bg-line/40" />
          ) : (
            <RingChart
              slices={paymentRings}
              centerValue={`${paymentsQ.data?.total ?? 0}`}
              centerLabel="jami to'lov"
            />
          )}
        </Panel>

        <Panel
          title="Nutq bahosi taqsimoti"
          subtitle="Mijozlarning so'nggi natijalari"
          icon={<TrendingUp size={17} strokeWidth={1.75} />}
          className="lg:col-span-3"
        >
          {clientsQ.isLoading ? (
            <div className="h-40 animate-pulse rounded-xl bg-line/40" />
          ) : (
            <BarChart
              data={scoreDist}
              unit=""
              emptyText="Hali baholangan mijozlar yo'q"
            />
          )}
        </Panel>
      </div>

      {/* ── Activity row ───────────────────────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <RecentClients
          rows={clientsQ.data?.items ?? []}
          loading={clientsQ.isLoading}
        />
        <RecentHomeworks
          rows={(pendingQ.data ?? []).slice(0, 5) as Homework[]}
          loading={pendingQ.isLoading}
        />
        <RecentPayments
          rows={paymentsQ.data?.items ?? []}
          loading={paymentsQ.isLoading}
        />
      </div>

      {/* ── Performers & curators row ─────────────────────── */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <Panel
          title="Eng yaxshi natijalar"
          subtitle="Eng yuqori nutq baliga ega mijozlar"
          icon={<TrendingUp size={17} strokeWidth={1.75} />}
          className="lg:col-span-2"
        >
          {clientsQ.isLoading ? (
            <SkeletonList rows={5} />
          ) : topPerformers.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              Hali baholangan mijozlar yo'q
            </p>
          ) : (
            <ol className="space-y-2">
              {topPerformers.map((c, idx) => (
                <li key={c.id}>
                  <Link
                    to={`/clients/${c.id}`}
                    className="flex items-center gap-3 rounded-xl border border-line/60 p-3 transition hover:border-wine/30 hover:bg-wine-50/50 dark:hover:bg-wine-900/20"
                  >
                    <span
                      className={`grid h-7 w-7 shrink-0 place-items-center rounded-lg text-xs font-black ${
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

        <Panel
          title="Kurator jamoasi"
          subtitle={`${totalCurators} ta kurator`}
          icon={<GraduationCap size={17} strokeWidth={1.75} />}
          action={
            <Link
              to="/curators"
              className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5 dark:text-wine-300"
            >
              Boshqarish <ChevronRight size={12} />
            </Link>
          }
        >
          {curatorsQ.isLoading ? (
            <SkeletonList rows={3} />
          ) : curatorsQ.data?.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">
              Hali kuratorlar yo'q
            </p>
          ) : (
            <ul className="space-y-2">
              {curatorsQ.data?.slice(0, 5).map((c) => (
                <li
                  key={c.id}
                  className="flex items-center gap-3 rounded-xl p-2"
                >
                  <div
                    className={`grid h-9 w-9 place-items-center rounded-lg text-xs font-black ${
                      c.is_active
                        ? "bg-wine text-white"
                        : "bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                    }`}
                  >
                    KR
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-bold text-ink">
                      {c.full_name ?? "Nomsiz kurator"}
                    </div>
                    <div className="truncate text-xs text-muted">
                      {c.email}
                    </div>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-bold ${
                      c.is_active
                        ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                        : "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400"
                    }`}
                  >
                    {c.is_active ? "Faol" : "Bloklangan"}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>

      {isLoading && (
        <p className="text-center text-xs text-muted">
          Ma'lumotlar yuklanmoqda…
        </p>
      )}
    </div>
  );
}

// ─── QuickLink ─────────────────────────────────────────────────────────────

function QuickLink({
  to,
  label,
  value,
  icon: Icon,
  tone,
  smallValue,
}: {
  to: string;
  label: string;
  value: number | string;
  icon: LucideIcon;
  tone: string;
  smallValue?: boolean;
}) {
  return (
    <Link
      to={to}
      className="group flex items-center gap-3 rounded-2xl border border-line bg-card p-4 transition hover:border-wine/30 hover:shadow-md hover:shadow-wine/5"
    >
      <div
        className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${tone}`}
      >
        <Icon size={18} strokeWidth={1.75} />
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
