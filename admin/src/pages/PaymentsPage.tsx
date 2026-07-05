import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { api, apiError } from "../lib/api";
import type { Page, Payment } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

const PROVIDER_LABELS: Record<Payment["provider"], string> = {
  uzum: "Uzum",
  uzum_nasiya: "Uzum Nasiya",
  atmos: "ATMOS",
};

type StatusFilter = "all" | Payment["status"];

export function PaymentsPage() {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const { t } = useLang();
  const size = 20;

  const STATUS_STYLES: Record<Payment["status"], { label: string; classes: string }> = {
    pending: { label: t.payments.pending, classes: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400" },
    paid: { label: t.payments.paid, classes: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" },
    failed: { label: t.payments.failed, classes: "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" },
    refunded: { label: t.payments.refunded, classes: "bg-line text-muted" },
  };

  const PURPOSE_LABELS: Record<Payment["purpose"], string> = {
    course: t.payments.course,
    audiobook: t.payments.audiobook,
    subscription: t.payments.subscription,
  };

  const { data, isLoading, error } = useQuery({
    queryKey: ["payments", page, statusFilter],
    queryFn: async () => {
      const params: Record<string, string | number> = { page, size };
      if (statusFilter !== "all") params.status = statusFilter;
      return (await api.get<Page<Payment>>("/admin/payments", { params })).data;
    },
  });

  const totalPages = data ? Math.ceil(data.total / size) : 1;

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader title={t.payments.title} subtitle={t.payments.subtitle} />

      <div className="mb-5 flex flex-wrap gap-2">
        {(["all", "pending", "paid", "failed", "refunded"] as StatusFilter[]).map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1); }}
            className={`rounded-xl px-4 py-1.5 text-sm font-semibold transition ${
              statusFilter === s
                ? "bg-wine text-white"
                : "border border-line bg-card text-muted hover:border-wine/40 hover:text-ink"
            }`}
          >
            {s === "all" ? t.common.all : STATUS_STYLES[s as Payment["status"]].label}
          </button>
        ))}
      </div>

      <div className="overflow-x-auto rounded-2xl border border-line bg-card">
        {isLoading && <p className="p-6 text-sm text-muted">{t.common.loading}</p>}
        {error && <p className="p-6 text-sm text-red-500 dark:text-red-400">{apiError(error)}</p>}
        {data && (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-line bg-wine-50 dark:bg-wine-900/20">
                <th className="px-5 py-3 text-left text-xs font-semibold text-muted">{t.payments.date}</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-muted">{t.payments.user}</th>
                <th className="px-5 py-3 text-right text-xs font-semibold text-muted">{t.payments.amount}</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-muted">{t.payments.provider}</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-muted">{t.payments.purpose}</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-muted">{t.payments.status}</th>
              </tr>
            </thead>
            <tbody>
              {data.items.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-muted">
                    {t.payments.noPayments}
                  </td>
                </tr>
              )}
              {data.items.map((payment) => {
                const status = STATUS_STYLES[payment.status];
                return (
                  <tr key={payment.id} className="border-b border-line last:border-none hover:bg-wine-50 dark:hover:bg-wine-900/20">
                    <td className="px-5 py-3 text-muted">{formatDate(payment.created_at)}</td>
                    <td className="px-5 py-3 font-mono text-xs text-ink">{payment.user_id.slice(0, 8)}…</td>
                    <td className="px-5 py-3 text-right font-semibold text-ink">
                      {formatAmount(payment.amount, payment.currency)}
                    </td>
                    <td className="px-5 py-3 text-ink">{PROVIDER_LABELS[payment.provider]}</td>
                    <td className="px-5 py-3 text-ink">{PURPOSE_LABELS[payment.purpose]}</td>
                    <td className="px-5 py-3">
                      <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${status.classes}`}>
                        {status.label}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {data && totalPages > 1 && (
        <div className="mt-5 flex items-center justify-between">
          <p className="text-sm text-muted">
            <span className="font-semibold text-ink">{data.total}</span>
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-line text-muted hover:border-wine/40 hover:text-ink disabled:opacity-40"
            >
              <ChevronLeft size={16} />
            </button>
            <span className="text-sm font-semibold text-ink">{page} / {totalPages}</span>
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

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("uz-UZ", {
      year: "numeric", month: "2-digit", day: "2-digit",
      hour: "2-digit", minute: "2-digit",
    });
  } catch { return iso; }
}

function formatAmount(amount: string, currency: string): string {
  try {
    return parseFloat(amount).toLocaleString("uz-UZ") + " " + (currency?.toUpperCase() ?? "UZS");
  } catch { return amount; }
}
