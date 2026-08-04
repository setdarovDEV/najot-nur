import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Bell } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, Spinner } from "../../components/glass";
import type { AppNotification } from "../../lib/types";

export function NotificationsPage() {
  const navigate = useNavigate();
  const { t } = useLang();

  const notifQ = useQuery({
    queryKey: ["notifications"],
    queryFn: async () => (await api.get<AppNotification[]>("/users/me/notifications")).data,
  });

  const notifications = notifQ.data ?? [];

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>
      <h1 className="text-xl font-black text-ink">{t.notifications.title}</h1>
      <p className="mt-1 text-xs text-muted sm:text-sm">{t.notifications.subtitle}</p>

      <div className="mt-5 space-y-2">
        {notifQ.isLoading ? (
          <div className="py-16"><Spinner /></div>
        ) : notifications.length === 0 ? (
          <GlassCard className="p-10 text-center">
            <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
              <Bell size={26} />
            </div>
            <p className="mt-3 text-sm text-muted">{t.notifications.noData}</p>
          </GlassCard>
        ) : (
          notifications.map((n) => (
            <GlassCard key={n.id} className="flex items-start gap-4 p-4">
              <div className="grid h-10 w-10 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                <Bell size={18} />
              </div>
              <div className="min-w-0 flex-1">
                <div className="text-sm font-extrabold text-ink">{n.title}</div>
                {n.body && <p className="mt-1 text-xs leading-relaxed text-muted">{n.body}</p>}
                {n.sent_at && (
                  <div className="mt-1.5 text-[11px] text-muted">
                    {new Date(n.sent_at).toLocaleString()}
                  </div>
                )}
              </div>
            </GlassCard>
          ))
        )}
      </div>
    </div>
  );
}
