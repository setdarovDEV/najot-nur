import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, ChevronLeft, ChevronRight, X } from "lucide-react";
import { api, apiError } from "../lib/api";
import type { Order, Page } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

// ─── Label maps ───────────────────────────────────────────────────────────────

const METHOD_LABELS: Record<Order["payment_method"], string> = {
  click: "Click",
  payme: "Payme",
  cash: "Naqd pul",
};

const METHOD_STYLES: Record<Order["payment_method"], string> = {
  click: "bg-blue-100 text-blue-700",
  payme: "bg-teal-100 text-teal-700",
  cash: "bg-green-100 text-green-700 font-extrabold",
};

const STATUS_STYLES: Record<
  Order["status"],
  { label: string; classes: string }
> = {
  pending: { label: "Kutilmoqda", classes: "bg-yellow-100 text-yellow-700" },
  approved: { label: "Tasdiqlangan", classes: "bg-green-100 text-green-700" },
  rejected: { label: "Rad etilgan", classes: "bg-red-100 text-red-600" },
};

type StatusFilter = "all" | Order["status"];
type MethodFilter = "all" | Order["payment_method"];

// ─── OrdersPage ───────────────────────────────────────────────────────────────

export function OrdersPage() {
  const qc = useQueryClient();
  const { t } = useLang();
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
    onSuccess: () => qc.invalidateQueries({ queryKey: ["orders"] }),
  });

  const reject = useMutation({
    mutationFn: ({ id, note }: { id: string; note: string }) =>
      api.patch(`/admin/orders/${id}/reject`, { admin_note: note || null }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["orders"] }),
  });

  const totalPages = data ? Math.ceil(data.total / size) : 1;

  return (
    <div className="p-8">
      <PageHeader title={t.orders.title} subtitle={t.orders.subtitle} />

      {/* Status filter */}
      <div className="mb-3 flex flex-wrap gap-2">
        {(["pending", "approved", "rejected", "all"] as StatusFilter[]).map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1); }}
            className={`rounded-xl px-4 py-1.5 text-sm font-semibold transition ${
              statusFilter === s
                ? "bg-wine text-white"
                : "border border-line bg-card text-muted hover:border-wine/40 hover:text-ink"
            }`}
          >
            {s === "all" ? "Barchasi" : STATUS_STYLES[s as Order["status"]].label}
          </button>
        ))}
      </div>

      {/* Method filter */}
      <div className="mb-5 flex flex-wrap gap-2">
        {(["all", "click", "payme", "cash"] as MethodFilter[]).map((m) => (
          <button
            key={m}
            onClick={() => { setMethodFilter(m); setPage(1); }}
            className={`rounded-xl px-3 py-1 text-xs font-semibold transition ${
              methodFilter === m
                ? "bg-ink text-card"
                : "border border-line bg-card text-muted hover:border-ink/30 hover:text-ink"
            }`}
          >
            {m === "all" ? "Barcha usul" : METHOD_LABELS[m as Order["payment_method"]]}
          </button>
        ))}
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

          {data.items.map((order) => {
            const st = STATUS_STYLES[order.status];
            const note = actionNote[order.id] ?? "";
            const isPending = order.status === "pending";
            const busy =
              approve.isPending || reject.isPending;

            return (
              <div
                key={order.id}
                className="rounded-2xl border border-line bg-card p-5 shadow-sm"
              >
                {/* Header row */}
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${st.classes}`}>
                      {st.label}
                    </span>
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${METHOD_STYLES[order.payment_method]}`}>
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
                    <input
                      type="text"
                      placeholder="Admin izohi (ixtiyoriy)"
                      value={note}
                      onChange={(e) =>
                        setActionNote((prev) => ({ ...prev, [order.id]: e.target.value }))
                      }
                      className="min-w-0 flex-1 rounded-xl border border-line px-3 py-1.5 text-sm text-ink placeholder:text-muted focus:border-wine/60 focus:outline-none"
                    />
                    <button
                      disabled={busy}
                      onClick={() => approve.mutate({ id: order.id, note })}
                      className="flex items-center gap-1.5 rounded-xl bg-green-600 px-4 py-1.5 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-50"
                    >
                      <Check size={14} />
                      Tasdiqlash
                    </button>
                    <button
                      disabled={busy}
                      onClick={() => reject.mutate({ id: order.id, note })}
                      className="flex items-center gap-1.5 rounded-xl bg-red-600 px-4 py-1.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                    >
                      <X size={14} />
                      Rad etish
                    </button>
                  </div>
                )}
              </div>
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
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-line text-muted hover:border-wine/40 hover:text-ink disabled:opacity-40"
            >
              <ChevronLeft size={16} />
            </button>
            <span className="text-sm font-semibold text-ink">
              {page} / {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-line text-muted hover:border-wine/40 hover:text-ink disabled:opacity-40"
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
