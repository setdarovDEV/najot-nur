import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, apiError } from "../lib/api";
import type { CertificateRequest } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

type StatusFilter = "pending" | "approved" | "rejected" | "";

export function CertificateRequestsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
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
    onSuccess: () => qc.invalidateQueries({ queryKey: ["certificate-requests"] }),
  });

  const reject = useMutation({
    mutationFn: (vars: { id: string; reason: string }) =>
      api.post(`/admin/certificate-requests/${vars.id}/reject`, {
        reason: vars.reason || null,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["certificate-requests"] }),
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
            onApprove={() => {
              if (window.confirm(cr.confirmApprove(req.full_name))) {
                approve.mutate(req.id);
              }
            }}
            onReject={(reason) => {
              if (window.confirm(cr.confirmReject)) {
                reject.mutate({ id: req.id, reason });
              }
            }}
          />
        ))}
      </div>

      {(approve.isError || reject.isError) && (
        <p className="mt-3 text-sm text-red-500">
          {apiError(approve.error ?? reject.error)}
        </p>
      )}
    </div>
  );
}

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
  const [approving, setApproving] = useState(false);
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
        <span className={`rounded-full px-3 py-1 text-xs font-semibold ${statusColor}`}>
          {statusLabel}
        </span>
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
              try {
                onReject(reason);
              } finally {
                setRejecting(false);
              }
            }}
            className="rounded-lg border border-red-300 px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/20"
          >
            {rejecting ? cr.rejecting : cr.reject}
          </button>
          <button
            disabled={approving}
            onClick={async () => {
              setApproving(true);
              try {
                onApprove();
              } finally {
                setApproving(false);
              }
            }}
            className="rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white hover:bg-wine-dark disabled:opacity-60"
          >
            {approving ? cr.approving : cr.approve}
          </button>
        </div>
      )}
    </div>
  );
}
