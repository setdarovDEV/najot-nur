import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, apiError } from "../lib/api";
import type { CertificateRequest, StudentStats } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";

type StatusFilter = "pending" | "approved" | "rejected" | "";

export function CertificateRequestsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const [filter, setFilter] = useState<StatusFilter>("pending");

  const { data, isLoading } = useQuery({
    queryKey: ["certificate-requests", filter],
    queryFn: async () =>
      (
        await api.get<CertificateRequest[]>("/admin/certificate-requests", {
          params: { status: filter || undefined },
        })
      ).data,
  });

  const approve = useMutation({
    mutationFn: (id: string) =>
      api.post(`/admin/certificate-requests/${id}/approve`),
    onSuccess: () => {
      toast.success(t.certificateRequests.approveSuccess);
      qc.invalidateQueries({ queryKey: ["certificate-requests"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const reject = useMutation({
    mutationFn: (vars: { id: string; reason: string }) =>
      api.post(`/admin/certificate-requests/${vars.id}/reject`, {
        reason: vars.reason || null,
      }),
    onSuccess: () => {
      toast.success(t.certificateRequests.rejectSuccess);
      qc.invalidateQueries({ queryKey: ["certificate-requests"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const cr = t.certificateRequests;

  return (
    <div className="p-8">
      <PageHeader
        title={cr.title}
        subtitle={cr.subtitle}
        actions={
          <div className="flex gap-2">
            {(["pending", "approved", "rejected", ""] as const).map((f) => (
              <button
                key={f || "all"}
                onClick={() => setFilter(f)}
                className={`rounded-lg px-4 py-2 text-sm font-semibold ${
                  filter === f
                    ? "bg-wine text-white"
                    : "border border-line bg-card text-ink hover:bg-wine-50"
                }`}
              >
                {f === "pending"
                  ? cr.pending
                  : f === "approved"
                    ? cr.approved
                    : f === "rejected"
                      ? cr.rejected
                      : cr.all}
              </button>
            ))}
          </div>
        }
      />

      {isLoading && <p className="text-muted">{t.common.loading}</p>}
      {data && data.length === 0 && (
        <p className="rounded-xl border border-line bg-card p-6 text-muted">
          {cr.noRequests}
        </p>
      )}

      <div className="space-y-4">
        {data?.map((req) => (
          <CertRequestCard
            key={req.id}
            req={req}
            onApprove={async () => {
              const ok = await confirm({
                title: cr.confirmApprove(req.full_name),
                variant: "primary",
                confirmText: t.modal.approve,
              });
              if (ok) approve.mutate(req.id);
            }}
            onReject={async (reason) => {
              const ok = await confirm({
                title: cr.confirmReject,
                variant: "danger",
                confirmText: t.modal.reject,
              });
              if (ok) reject.mutate({ id: req.id, reason });
            }}
          />
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Certificate request card with expandable student stats
// ─────────────────────────────────────────────────────────────

function CertRequestCard({
  req,
  onApprove,
  onReject,
}: {
  req: CertificateRequest;
  onApprove: () => void;
  onReject: (reason: string) => void;
}) {
  const { t } = useLang();
  const cr = t.certificateRequests;
  const [reason, setReason] = useState("");
  const [showStats, setShowStats] = useState(false);

  const statsQuery = useQuery({
    queryKey: ["cert-student-stats", req.id],
    queryFn: async () =>
      (await api.get<StudentStats>(`/admin/certificate-requests/${req.id}/student-stats`)).data,
    enabled: showStats,
    staleTime: 60_000,
  });

  const statusColor =
    req.status === "approved"
      ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
      : req.status === "rejected"
        ? "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
        : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400";

  const statusLabel =
    req.status === "approved"
      ? cr.approved
      : req.status === "rejected"
        ? cr.rejected
        : cr.pending;

  return (
    <div className="rounded-2xl border border-line bg-card overflow-hidden">
      {/* ── Header ── */}
      <div className="p-5">
        <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
          <div>
            <p className="font-bold text-ink">
              {cr.user}: {req.user_full_name ?? "—"}{" "}
              {req.user_phone && (
                <span className="font-normal text-muted">({req.user_phone})</span>
              )}
            </p>
            <p className="mt-0.5 text-sm text-muted">
              {cr.course}: <span className="font-semibold text-ink">{req.course_title}</span>
            </p>
            <p className="mt-0.5 text-sm text-muted">
              {cr.fullName}: <span className="font-semibold text-ink">{req.full_name}</span>
            </p>
            <p className="mt-0.5 text-xs text-muted">
              {cr.date}: {new Date(req.created_at).toLocaleString()}
            </p>
            {req.rejection_reason && (
              <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                {req.rejection_reason}
              </p>
            )}
          </div>
          <span className={`rounded-full px-3 py-1 text-xs font-semibold ${statusColor}`}>
            {statusLabel}
          </span>
        </div>

        {/* ── Actions ── */}
        <div className="flex flex-wrap items-center gap-3">
          {/* View stats toggle */}
          <button
            onClick={() => setShowStats((v) => !v)}
            className="flex items-center gap-1.5 rounded-lg border border-line px-3 py-1.5 text-sm font-semibold text-ink hover:bg-line/40"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            {showStats ? cr.hideStats : cr.viewStats}
          </button>

          {req.status === "pending" && (
            <>
              <input
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder={cr.reasonPlaceholder}
                className="flex-1 rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
              />
              <button
                onClick={() => onReject(reason)}
                className="rounded-lg border border-red-300 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/20"
              >
                {cr.reject}
              </button>
              <button
                onClick={onApprove}
                className="rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white hover:bg-wine-dark"
              >
                {cr.approve}
              </button>
            </>
          )}
        </div>
      </div>

      {/* ── Student stats panel ── */}
      {showStats && (
        <div className="border-t border-line bg-[#faf9fb] px-5 py-5 dark:bg-[#1e1a20]">
          {statsQuery.isLoading && (
            <p className="text-sm text-muted">{cr.statsLoading}</p>
          )}
          {statsQuery.isError && (
            <p className="text-sm text-red-500">{apiError(statsQuery.error)}</p>
          )}
          {statsQuery.data && <StudentStatsPanel stats={statsQuery.data} />}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Student stats display
// ─────────────────────────────────────────────────────────────

function StudentStatsPanel({ stats }: { stats: StudentStats }) {
  const { t } = useLang();
  const cr = t.certificateRequests;

  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
      {/* ── 1. Kurs jarayoni ── */}
      <section>
        <h3 className="mb-3 flex items-center gap-2 text-sm font-bold text-ink">
          <span className="text-base">🎓</span> {cr.courseProgress}
        </h3>

        {/* Progress bar */}
        <div className="mb-3">
          <div className="mb-1 flex justify-between text-xs text-muted">
            <span>{cr.lessonsCompleted(stats.course.lessons_completed, stats.course.lessons_total)}</span>
            <span>{cr.progressPct(stats.course.progress_pct)}</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-line">
            <div
              className="h-full rounded-full bg-wine transition-all"
              style={{ width: `${stats.course.progress_pct}%` }}
            />
          </div>
          <p className="mt-1 text-xs text-muted">
            {stats.course.status === "completed" ? (
              <span className="font-semibold text-green-600">{cr.statusCompleted}</span>
            ) : (
              <span className="font-semibold text-amber-600">{cr.statusActive}</span>
            )}
          </p>
        </div>

        {/* Lesson list */}
        <div className="max-h-56 overflow-y-auto rounded-xl border border-line bg-card">
          {stats.course.lessons.map((ls, i) => (
            <div
              key={i}
              className="flex items-center justify-between border-b border-line px-3 py-2 last:border-0"
            >
              <div className="flex items-center gap-2 min-w-0">
                <span className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-xs font-bold ${
                  ls.completed ? "bg-green-100 text-green-700" : "bg-line text-muted"
                }`}>
                  {ls.completed ? "✓" : ls.order_index}
                </span>
                <span className="truncate text-xs text-ink">{ls.title}</span>
              </div>
              {ls.quiz_score != null && (
                <span className={`ml-2 shrink-0 rounded-full px-2 py-0.5 text-xs font-bold ${
                  ls.quiz_score >= 70 ? "bg-green-100 text-green-700" : "bg-red-100 text-red-600"
                }`}>
                  {ls.quiz_score}%
                </span>
              )}
            </div>
          ))}
        </div>
      </section>

      <div className="flex flex-col gap-6">
        {/* ── 2. Audiokitoblar ── */}
        <section>
          <h3 className="mb-2 flex items-center gap-2 text-sm font-bold text-ink">
            <span className="text-base">🎧</span> {cr.audiobooksTitle}
          </h3>
          {stats.audiobooks.length === 0 ? (
            <p className="text-xs text-muted">{cr.noAudiobooks}</p>
          ) : (
            <div className="space-y-2">
              <p className="text-xs text-muted mb-1">
                {cr.audiobooksCount(stats.audiobooks.length)}
              </p>
              {stats.audiobooks.map((ab, i) => (
                <div key={i} className="rounded-lg border border-line bg-card p-2.5">
                  <p className="text-xs font-semibold text-ink truncate">{ab.title}</p>
                  {ab.author && <p className="text-xs text-muted">{ab.author}</p>}
                  <div className="mt-1.5 flex items-center gap-2">
                    <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-line">
                      <div
                        className="h-full rounded-full bg-wine"
                        style={{ width: ab.total_pages > 0 ? `${Math.min(100, (ab.current_page / ab.total_pages) * 100)}%` : "0%" }}
                      />
                    </div>
                    <span className="text-xs text-muted shrink-0">
                      {cr.pageProgress(ab.current_page, ab.total_pages)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* ── 3. Praktikum natijalari ── */}
        <section>
          <h3 className="mb-2 flex items-center gap-2 text-sm font-bold text-ink">
            <span className="text-base">🎤</span> {cr.practicumsTitle}
          </h3>
          {stats.practicums.length === 0 ? (
            <p className="text-xs text-muted">{cr.noPracticums}</p>
          ) : (
            <div className="space-y-2">
              {stats.practicums.map((p, i) => (
                <div key={i} className="flex items-center justify-between rounded-lg border border-line bg-card px-3 py-2">
                  <span className="text-xs text-ink truncate mr-2">{p.title}</span>
                  {p.score != null ? (
                    <span className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-bold ${
                      p.score >= 70 ? "bg-green-100 text-green-700" : "bg-red-100 text-red-600"
                    }`}>
                      {p.score}%
                    </span>
                  ) : (
                    <span className="shrink-0 text-xs text-muted">—</span>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* ── 4. Nutq tahlili ── (full width) */}
      <section className="md:col-span-2">
        <h3 className="mb-2 flex items-center gap-2 text-sm font-bold text-ink">
          <span className="text-base">📊</span> {cr.speechTitle}
        </h3>
        {stats.speech_analyses.length === 0 ? (
          <p className="text-xs text-muted">{cr.noSpeech}</p>
        ) : (
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {stats.speech_analyses.map((s, i) => (
              <div key={i} className="rounded-lg border border-line bg-card p-3">
                <p className="mb-2 text-xs text-muted">
                  {new Date(s.created_at).toLocaleDateString()}
                </p>
                <div className="flex gap-3">
                  <ScoreBadge label={cr.overall} value={s.overall_score} primary />
                  <ScoreBadge label={cr.meaning} value={s.meaning_score} />
                  <ScoreBadge label={cr.fluency} value={s.fluency_score} />
                </div>
                {s.summary && (
                  <p className="mt-2 text-xs text-muted line-clamp-2">{s.summary}</p>
                )}
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function ScoreBadge({
  label,
  value,
  primary = false,
}: {
  label: string;
  value: number | null;
  primary?: boolean;
}) {
  const color =
    value == null
      ? "text-muted"
      : value >= 70
        ? "text-green-600"
        : value >= 50
          ? "text-amber-600"
          : "text-red-600";

  return (
    <div className="text-center">
      <p className={`text-xs font-bold ${color} ${primary ? "text-base" : ""}`}>
        {value != null ? value : "—"}
      </p>
      <p className="text-[10px] text-muted">{label}</p>
    </div>
  );
}
