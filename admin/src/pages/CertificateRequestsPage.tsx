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
  const [statsReqId, setStatsReqId] = useState<string | null>(null);

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
      setStatsReqId(null);
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
      setStatsReqId(null);
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const cr = t.certificateRequests;
  const statsReq = data?.find((r) => r.id === statsReqId) ?? null;

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={cr.title}
        subtitle={cr.subtitle}
        actions={
          <>
            {(["pending", "approved", "rejected", ""] as const).map((f) => (
              <button
                key={f || "all"}
                onClick={() => setFilter(f)}
                className={`rounded-lg px-4 py-2 text-sm font-semibold ${
                  filter === f
                    ? "bg-wine text-white"
                    : "border border-line bg-card text-ink hover:bg-wine-50 dark:hover:bg-wine-900/20"
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
          </>
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
            onViewStats={() => setStatsReqId(req.id)}
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

      {statsReq && (
        <StudentStatsModal
          req={statsReq}
          onClose={() => setStatsReqId(null)}
          onApprove={async () => {
            const ok = await confirm({
              title: cr.confirmApprove(statsReq.full_name),
              variant: "primary",
              confirmText: t.modal.approve,
            });
            if (ok) approve.mutate(statsReq.id);
          }}
          onReject={async (reason) => {
            const ok = await confirm({
              title: cr.confirmReject,
              variant: "danger",
              confirmText: t.modal.reject,
            });
            if (ok) reject.mutate({ id: statsReq.id, reason });
          }}
          approving={approve.isPending}
          rejecting={reject.isPending}
        />
      )}
    </div>
  );
}

// ─── Student stats modal ──────────────────────────────────────────────────────

function StudentStatsModal({
  req,
  onClose,
  onApprove,
  onReject,
  approving,
  rejecting,
}: {
  req: CertificateRequest;
  onClose: () => void;
  onApprove: () => void;
  onReject: (reason: string) => void;
  approving: boolean;
  rejecting: boolean;
}) {
  const { t } = useLang();
  const cr = t.certificateRequests;
  const [rejectReason, setRejectReason] = useState("");

  const { data: stats, isLoading, isError } = useQuery({
    queryKey: ["cert-stats", req.id],
    queryFn: async () =>
      (await api.get<StudentStats>(`/admin/certificate-requests/${req.id}/student-stats`)).data,
  });

  const progress = stats?.course?.progress_pct ?? 0;
  const canApprove = progress >= 100;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="relative flex max-h-[90vh] w-full max-w-2xl flex-col rounded-2xl bg-white shadow-2xl dark:bg-[#1c1417]">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-line px-6 py-4">
          <div>
            <h2 className="text-lg font-bold text-ink">{cr.statsTitle}</h2>
            <p className="mt-0.5 text-sm text-muted">
              {req.user_full_name} · {req.user_phone} · <span className="font-semibold text-ink">{req.course_title}</span>
            </p>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-muted hover:bg-line"
          >
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-6 py-5 space-y-6">
          {isLoading && <p className="text-muted">{t.common.loading}</p>}
          {isError && <p className="text-red-500">{cr.noStats}</p>}

          {stats && (
            <>
              {/* Course progress */}
              <section>
                <h3 className="mb-3 flex items-center gap-2 font-bold text-ink">
                  <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-wine/10 text-wine text-sm">📚</span>
                  {cr.courseProgress}
                </h3>
                <div className="rounded-xl border border-line bg-card p-4 space-y-3">
                  {/* Progress bar */}
                  <div>
                    <div className="mb-1 flex justify-between text-sm">
                      <span className="text-muted">{cr.lessonsCompleted(stats.course.lessons_completed, stats.course.lessons_total)}</span>
                      <span className={`font-bold ${canApprove ? "text-green-600" : "text-amber-600"}`}>
                        {cr.progressPct(progress)}
                      </span>
                    </div>
                    <div className="h-2.5 w-full rounded-full bg-line">
                      <div
                        className={`h-2.5 rounded-full transition-all ${canApprove ? "bg-green-500" : "bg-wine"}`}
                        style={{ width: `${Math.min(progress, 100)}%` }}
                      />
                    </div>
                  </div>

                  {/* Status badge */}
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-muted">Status:</span>
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                      stats.course.status === "completed"
                        ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                        : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
                    }`}>
                      {stats.course.status}
                    </span>
                  </div>

                  {/* Lessons table */}
                  {stats.course.lessons.length > 0 && (
                    <div className="mt-2 max-h-44 overflow-y-auto rounded-lg border border-line">
                      <table className="w-full text-sm">
                        <thead className="bg-line/50">
                          <tr>
                            <th className="px-3 py-2 text-left font-semibold text-muted">#</th>
                            <th className="px-3 py-2 text-left font-semibold text-muted">Dars</th>
                            <th className="px-3 py-2 text-center font-semibold text-muted">{cr.lessonDone}</th>
                            <th className="px-3 py-2 text-center font-semibold text-muted">{cr.quizScore}</th>
                          </tr>
                        </thead>
                        <tbody>
                          {stats.course.lessons.map((ls, i) => (
                            <tr key={i} className="border-t border-line">
                              <td className="px-3 py-2 text-muted">{ls.order_index + 1}</td>
                              <td className="px-3 py-2 text-ink">{ls.title}</td>
                              <td className="px-3 py-2 text-center">
                                {ls.completed
                                  ? <span className="text-green-500">✓</span>
                                  : <span className="text-muted">—</span>}
                              </td>
                              <td className="px-3 py-2 text-center">
                                {ls.quiz_score != null
                                  ? <span className={`font-semibold ${ls.quiz_score >= 80 ? "text-green-600" : ls.quiz_score >= 50 ? "text-amber-600" : "text-red-500"}`}>{ls.quiz_score}</span>
                                  : <span className="text-muted">—</span>}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </section>

              {/* Practicums */}
              {stats.practicums.length > 0 && (
                <section>
                  <h3 className="mb-3 flex items-center gap-2 font-bold text-ink">
                    <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-100 text-blue-600 text-sm">🎤</span>
                    {cr.practiculms}
                  </h3>
                  <div className="space-y-2">
                    {stats.practicums.map((p, i) => (
                      <div key={i} className="flex items-center justify-between rounded-lg border border-line bg-card px-4 py-2.5">
                        <div>
                          <p className="font-semibold text-ink text-sm">{p.title}</p>
                          <p className="text-xs text-muted">{new Date(p.submitted_at).toLocaleDateString()}</p>
                        </div>
                        {p.score != null && (
                          <span className={`rounded-full px-3 py-1 text-sm font-bold ${
                            p.score >= 80 ? "bg-green-100 text-green-700" : p.score >= 50 ? "bg-amber-100 text-amber-700" : "bg-red-100 text-red-600"
                          }`}>
                            {p.score}
                          </span>
                        )}
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Speech analyses */}
              {stats.speech_analyses.length > 0 && (
                <section>
                  <h3 className="mb-3 flex items-center gap-2 font-bold text-ink">
                    <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-purple-100 text-purple-600 text-sm">🗣️</span>
                    {cr.speechAnalyses}
                  </h3>
                  <div className="space-y-2">
                    {stats.speech_analyses.slice(0, 5).map((s, i) => (
                      <div key={i} className="rounded-lg border border-line bg-card px-4 py-2.5">
                        <div className="flex items-center justify-between">
                          <p className="text-xs text-muted">{new Date(s.created_at).toLocaleDateString()}</p>
                          <div className="flex gap-3 text-xs font-semibold">
                            <span className="text-muted">Umumiy: <span className="text-ink">{s.overall_score}</span></span>
                            <span className="text-muted">Mazmun: <span className="text-ink">{s.meaning_score}</span></span>
                            <span className="text-muted">Ravonlik: <span className="text-ink">{s.fluency_score}</span></span>
                          </div>
                        </div>
                        {s.summary && (
                          <p className="mt-1 text-xs text-muted line-clamp-1">{s.summary}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Audiobooks */}
              {stats.audiobooks.length > 0 && (
                <section>
                  <h3 className="mb-3 flex items-center gap-2 font-bold text-ink">
                    <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-orange-100 text-orange-600 text-sm">📖</span>
                    {cr.audiobooksRead}
                  </h3>
                  <div className="space-y-2">
                    {stats.audiobooks.map((ab, i) => (
                      <div key={i} className="flex items-center justify-between rounded-lg border border-line bg-card px-4 py-2.5">
                        <div>
                          <p className="font-semibold text-ink text-sm">{ab.title}</p>
                          {ab.author && <p className="text-xs text-muted">{ab.author}</p>}
                        </div>
                        <span className="text-sm text-muted">
                          {cr.page} {ab.current_page}/{ab.total_pages}
                        </span>
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </>
          )}
        </div>

        {/* Footer with approve/reject (only for pending) */}
        {req.status === "pending" && (
          <div className="border-t border-line px-6 py-4 space-y-3">
            {!canApprove && stats && (
              <p className="rounded-lg bg-amber-50 border border-amber-200 px-3 py-2 text-sm text-amber-700 dark:bg-amber-900/20 dark:border-amber-800 dark:text-amber-400">
                ⚠️ {cr.approveDisabled}
              </p>
            )}
            <div className="flex flex-wrap items-center gap-3">
              <input
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder={cr.reasonPlaceholder}
                className="flex-1 rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
              />
              <button
                disabled={rejecting}
                onClick={() => onReject(rejectReason)}
                className="rounded-lg border border-red-300 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/20"
              >
                {rejecting ? cr.rejecting : cr.reject}
              </button>
              <button
                disabled={approving || !canApprove || !stats}
                onClick={onApprove}
                title={!canApprove ? cr.approveDisabled : undefined}
                className="rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white hover:bg-wine-dark disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {approving ? cr.approving : cr.approve}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Request card (list view) ─────────────────────────────────────────────────

function CertRequestCard({
  req,
  onViewStats,
  onReject,
}: {
  req: CertificateRequest;
  onViewStats: () => void;
  onReject: (reason: string) => void;
}) {
  const { t } = useLang();
  const cr = t.certificateRequests;
  const [reason, setReason] = useState("");
  const [rejecting, setRejecting] = useState(false);

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
    <div className="rounded-2xl border border-line bg-card p-5">
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
        <div className="flex items-center gap-2">
          <span className={`rounded-full px-3 py-1 text-xs font-semibold ${statusColor}`}>
            {statusLabel}
          </span>
          {/* View stats button — always visible */}
          <button
            onClick={onViewStats}
            className="rounded-lg border border-wine/30 bg-wine/5 px-3 py-1.5 text-sm font-semibold text-wine hover:bg-wine/10 transition-colors"
          >
            {cr.viewStats}
          </button>
        </div>
      </div>

      {req.status === "pending" && (
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <input
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder={cr.reasonPlaceholder}
            className="flex-1 rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
          />
          <button
            disabled={rejecting}
            onClick={async () => {
              setRejecting(true);
              try { onReject(reason); } finally { setRejecting(false); }
            }}
            className="rounded-lg border border-red-300 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/20"
          >
            {rejecting ? cr.rejecting : cr.reject}
          </button>
          {/* Approve only from stats modal — shown as hint */}
          <button
            onClick={onViewStats}
            className="rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white hover:bg-wine-dark"
          >
            {cr.approve} →
          </button>
        </div>
      )}
    </div>
  );
}
