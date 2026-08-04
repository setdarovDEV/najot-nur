import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ShoppingCart } from "lucide-react";
import { api, formatSum } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, Spinner, StatusPill } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import type { Order } from "../../lib/types";

const METHOD_LABEL: Record<string, "methodUzum" | "methodNasiya" | "methodCash"> = {
  uzum: "methodUzum",
  uzum_nasiya: "methodNasiya",
  cash: "methodCash",
};

export function OrdersPage() {
  const navigate = useNavigate();
  const { t } = useLang();

  const ordersQ = useQuery({
    queryKey: ["my-orders"],
    queryFn: async () => (await api.get<Order[]>("/orders/my")).data,
  });

  const orders = ordersQ.data ?? [];

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>
      <PageHeader title={t.orders.title} subtitle={t.orders.subtitle} />

      {ordersQ.isLoading ? (
        <div className="py-16"><Spinner /></div>
      ) : orders.length === 0 ? (
        <GlassCard className="p-10 text-center">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
            <ShoppingCart size={26} />
          </div>
          <p className="mt-3 text-sm text-muted">{t.orders.noOrders}</p>
        </GlassCard>
      ) : (
        <div className="space-y-2">
          {orders.map((o) => (
            <GlassCard key={o.id} className="p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="truncate text-sm font-extrabold text-ink">
                      {o.target_title ?? (o.purpose === "course" ? t.orders.course : t.orders.audiobook)}
                    </span>
                    <StatusPill
                      tone={o.status === "approved" ? "success" : o.status === "rejected" ? "danger" : "warning"}
                    >
                      {t.orders[o.status]}
                    </StatusPill>
                  </div>
                  <div className="mt-1.5 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                    <span>{t.orders.date}: {new Date(o.created_at).toLocaleString()}</span>
                    <span>{t.orders.method}: {t.orders[METHOD_LABEL[o.payment_method] ?? "methodUzum"]}</span>
                    <span>{t.orders.amount}: {formatSum(o.amount)} so'm</span>
                  </div>
                  {o.admin_note && (
                    <p className="mt-2 rounded-xl bg-surface px-3 py-2 text-xs text-muted">
                      {t.orders.adminNote}: {o.admin_note}
                    </p>
                  )}
                </div>
              </div>
            </GlassCard>
          ))}
        </div>
      )}
    </div>
  );
}
