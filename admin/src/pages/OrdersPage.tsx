import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, ChevronLeft, ChevronRight, X } from "lucide-react";
import { api, apiError } from "../lib/api";
import type { Order, Page } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import { GlassCard, GlassInput, Reveal, SegmentedControl, StatusPill } from "../components/glass";

const STATUS_TONE: Record<Order["status"], "success" | "danger" | "warning"> = {
  pending: "warning",
  approved: "success",
  rejected: "danger",
};

// ─── Label maps ───────────────────────────────────────────────────────────────

const METHOD_LABELS: Record<Order["payment_method"], string> = {
  uzum: "Uzum",
  uzum_nasiya: "Uzum Nasiya",
  cash: "Naqd pul",
  gift: "🎁 Sovg'a",
};

const METHOD_STYLES: Record<Order["payment_method"], string> = {
  uzum: "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400",
  uzum_nasiya: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  cash: "bg-green-100 text-green-700 font-extrabold dark:bg-green-900/30 dark:text-green-400",
  gift: "bg-wine/10 text-wine font-extrabold dark:bg-wine/20 dark:text-wine-300",
};

const STATUS_STYLES: Record<
  Order["status"],
  { label: string; classes: string }
> = {
  pending: { label: "Kutilmoqda", classes: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400" },
  approved: { label: "Tasdiqlangan", classes: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" },
  rejected: { label: "Rad etilgan", classes: "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" },
};

type StatusFilter = "all" | Order["status"];
type MethodFilter = "all" | Order["payment_method"];

// ─── OrdersPage ───────────────────────────────────────────────────────────────

export function OrdersPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("pending");
  const [methodFilter, setMethodFilter] = useState<MethodFilter>("all");
  const [actionNote, setActionNote] = useState<Record<string, string>>({});
  const size = 20;

  const { data, isLoading, error } = useQuery({
    queryKey: ["orders", page, statusFilter, methodFilter],
    queryFn: async () => {
      const params: Record<string, string | number> = { page, size };
      if (statusFilter !== "all") params.status = statusFilter;
      if (methodFilter !== "all") params.payment_method = methodFilter;
      return (await api.get<Page<Order>>("/admin/orders", { params })).data;
    },
    refetchInterval: 30_000, // auto-refresh every 30s for live pending orders
  });

  const approve = useMutation({
    mutationFn: ({ id, note }: { id: string; note: string }) =>
      api.patch(`/admin/orders/${id}/approve`, { admin_note: note || null }),
    onSuccess: () => {
      toast.success("Buyurtma tasdiqlandi.");
      qc.invalidateQueries({ queryKey: ["orders"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const reject = useMutation({
    mutationFn: ({ id, note }: { id: string; note: string }) =>
      api.patch(`/admin/orders/${id}/reject`, { admin_note: note || null }),
    onSuccess: () => {
      toast.success("Buyurtma rad etildi.");
      qc.invalidateQueries({ queryKey: ["orders"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleApprove(id: string, note: string) {
    const ok = await confirm({
      title: "Buyurtmani tasdiqlashni tasdiqlaysizmi?",
      variant: "primary",
      confirmText: t.modal.approve,
    });
    if (ok) approve.mutate({ id, note });
  }

  async function handleReject(id: string, note: string) {
    const ok = await confirm({
      title: "Buyurtmani rad etishni tasdiqlaysizmi?",
      variant: "danger",
      confirmText: t.modal.reject,
    });
    if (ok) reject.mutate({ id, note });
  }

  const totalPages = data ? Math.ceil(data.total / size) : 1;

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader title={t.orders.title} subtitle={t.orders.subtitle} />

      {/* Status filter */}
      <div className="mb-3">
        <SegmentedControl
          value={statusFilter}
          onChange={(s) => { setStatusFilter(s); setPage(1); }}
          options={(["pending", "approved", "rejected", "all"] as StatusFilter[]).map((s) => ({
            value: s,
            label: s === "all" ? "Barchasi" : STATUS_STYLES[s as Order["status"]].label,
          }))}
        />
      </div>

      {/* Method filter */}
      <div className="mb-5">
        <SegmentedControl
          value={methodFilter}
          onChange={(m) => { setMethodFilter(m); setPage(1); }}
          options={(["all", "uzum", "uzum_nasiya", "cash"] as MethodFilter[]).map((m) => ({
            value: m,
            label: m === "all" ? "Barcha usul" : METHOD_LABELS[m as Order["payment_method"]],
          }))}
        />
      </div>

      {isLoading && <p className="text-sm text-muted">Yuklanmoqda…</p>}
      {error && <p className="text-sm text-red-600">{apiError(error)}</p>}

      {data && (
        <div className="space-y-3">
          {data.items.length === 0 && (
            <p className="rounded-2xl border border-line bg-card px-6 py-10 text-center text-sm text-muted">
              Zayavkalar topilmadi.
            </p>
          )}

          {data.items.map((order, i) => {
            const st = STATUS_STYLES[order.status];
            const note = actionNote[order.id] ?? "";
            const isPending = order.status === "pending";
            const busy =
              approve.isPending || reject.isPending;

            return (
              <Reveal key={order.id} index={i}>
              <GlassCard className="p-5 shadow-sm">
                {/* Header row */}
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <StatusPill tone={STATUS_TONE[order.status]}>{st.label}</StatusPill>
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${METHOD_STYLES[order.payment_method]}`}>
                      {order.payment_method === "cash" ? "💵 Naqd pul" : METHOD_LABELS[order.payment_method]}
                    </span>
                  </div>
                  <span className="text-xs text-muted">{formatDate(order.created_at)}</span>
                </div>

                {/* Details */}
                <div className="mt-3 grid grid-cols-2 gap-x-6 gap-y-2 text-sm md:grid-cols-4">
                  <Detail
                    label="Foydalanuvchi"
                    value={order.user_full_name ?? order.user_id.slice(0, 8) + "…"}
                  />
                  <Detail
                    label="Telefon"
                    value={
                      order.user_phone ? (
                        <a
                          href={`tel:${order.user_phone}`}
                          className="text-wine font-semibold"
                        >
                          {order.user_phone}
                        </a>
                      ) : (
                        <span className="text-muted">—</span>
                      )
                    }
                  />
                  <Detail
                    label={order.purpose === "audiobook" ? "Audio kitob" : "Kurs"}
                    value={order.target_title ?? "—"}
                  />
                  <Detail
                    label="Miqdor"
                    value={formatAmount(order.amount, order.currency)}
                  />
                  {order.payment_proof_url && (
                    <Detail
                      label="Chek"
                      value={
                        <a
                          href={order.payment_proof_url}
                          target="_blank"
                          rel="noreferrer"
                          className="text-wine underline"
                        >
                          Ko'rish
                        </a>
                      }
                    />
                  )}
                </div>

                {order.admin_note && (
                  <p className="mt-2 text-xs text-muted">
                    <span className="font-semibold">Izoh:</span> {order.admin_note}
                  </p>
                )}

                {/* Action area (only for pending orders) */}
                {isPending && (
                  <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-line pt-3">
                    <GlassInput
                      type="text"
                      placeholder="Admin izohi (ixtiyoriy)"
                      value={note}
                      onChange={(e) =>
                        setActionNote((prev) => ({ ...prev, [order.id]: e.target.value }))
                      }
                      className="min-w-0 flex-1 py-1.5"
                    />
                    <button
                      disabled={busy}
                      onClick={() => handleApprove(order.id, note)}
                      className="press flex items-center gap-1.5 rounded-full bg-green-600 px-4 py-1.5 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-50"
                    >
                      <Check size={14} />
                      Tasdiqlash
                    </button>
                    <button
                      disabled={busy}
                      onClick={() => handleReject(order.id, note)}
                      className="press flex items-center gap-1.5 rounded-full bg-red-600 px-4 py-1.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                    >
                      <X size={14} />
                      Rad etish
                    </button>
                  </div>
                )}
              </GlassCard>
              </Reveal>
            );
          })}
        </div>
      )}

      {/* Pagination */}
      {data && totalPages > 1 && (
        <div className="mt-5 flex items-center justify-between">
          <p className="text-sm text-muted">
            Jami: <span className="font-semibold text-ink">{data.total}</span> ta zayavka
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="press flex h-8 w-8 items-center justify-center rounded-full border border-line text-muted hover:border-wine/40 hover:text-ink disabled:opacity-40"
            >
              <ChevronLeft size={16} />
            </button>
            <span className="text-sm font-semibold text-ink">
              {page} / {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="press flex h-8 w-8 items-center justify-center rounded-full border border-line text-muted hover:border-wine/40 hover:text-ink disabled:opacity-40"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

function Detail({
  label,
  value,
  mono,
}: {
  label: string;
  value: React.ReactNode;
  mono?: boolean;
}) {
  return (
    <div>
      <p className="text-[10px] font-semibold uppercase tracking-wide text-muted">{label}</p>
      <p className={`text-sm text-ink ${mono ? "font-mono" : ""}`}>{value}</p>
    </div>
  );
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("uz-UZ", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

function formatAmount(amount: string, currency: string): string {
  try {
    return parseFloat(amount).toLocaleString("uz-UZ") + " " + (currency ?? "UZS");
  } catch {
    return amount;
  }
}
