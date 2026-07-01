import { Link } from "react-router-dom";
import { CreditCard, ChevronRight } from "lucide-react";
import { Panel } from "./Panel";
import type { Payment, PaymentStatus } from "../../lib/types";

const STATUS_STYLES: Record<
  PaymentStatus,
  { label: string; classes: string }
> = {
  pending: { label: "Kutilmoqda", classes: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400" },
  paid: { label: "To'langan", classes: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" },
  failed: { label: "Xato", classes: "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" },
  refunded: { label: "Qaytarilgan", classes: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400" },
};

const PURPOSE_LABELS: Record<string, string> = {
  course: "Kurs",
  audiobook: "Audiokitob",
  subscription: "Obuna",
};

function formatAmount(amount: string, currency: string): string {
  const num = parseFloat(amount);
  if (Number.isNaN(num)) return amount;
  return num.toLocaleString("uz-UZ") + " " + (currency?.toUpperCase() ?? "UZS");
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString("uz-UZ", {
    day: "2-digit",
    month: "short",
  });
}

export function RecentPayments({
  rows,
  loading,
}: {
  rows: Payment[];
  loading: boolean;
}) {
  return (
    <Panel
      title="So'nggi to'lovlar"
      subtitle="Eng yangi tranzaksiyalar"
      icon={<CreditCard size={17} strokeWidth={1.75} />}
      action={
        <Link
          to="/payments"
          className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-bold text-wine hover:bg-wine/5 dark:text-wine-300"
        >
          Hammasi <ChevronRight size={12} />
        </Link>
      }
    >
      {loading ? (
        <div className="space-y-2.5">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-12 animate-pulse rounded-xl bg-line/50" />
          ))}
        </div>
      ) : rows.length === 0 ? (
        <p className="py-6 text-center text-sm text-muted">
          Hali to'lovlar yo'q
        </p>
      ) : (
        <ul className="divide-y divide-line/60">
          {rows.map((p) => {
            const s = STATUS_STYLES[p.status];
            return (
              <li
                key={p.id}
                className="flex items-center justify-between gap-3 py-2.5 first:pt-0 last:pb-0"
              >
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-bold text-ink">
                    {formatAmount(p.amount, p.currency)}
                  </div>
                  <div className="mt-0.5 flex items-center gap-1.5 text-[11px] text-muted">
                    <span>{PURPOSE_LABELS[p.purpose] ?? p.purpose}</span>
                    <span>·</span>
                    <span>{formatDate(p.created_at)}</span>
                  </div>
                </div>
                <span
                  className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-bold ${s.classes}`}
                >
                  {s.label}
                </span>
              </li>
            );
          })}
        </ul>
      )}
    </Panel>
  );
}
