import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, CheckCircle2, FlaskConical, Loader2, Send } from "lucide-react";
import { api, apiError } from "../lib/api";
import type { AdminCourse, PushNotification, PushStatus } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import { GlassInput, GlassSelect, GlassTextarea, PrimaryButton, Reveal, SegmentedControl, StatusPill } from "../components/glass";

type Audience = "all" | "course" | "user" | "city";

interface AdminUserRow {
  id: string;
  full_name: string | null;
  phone: string | null;
  email: string | null;
  is_active: boolean;
}

const fetchCourses = () =>
  api.get<AdminCourse[]>("/admin/courses").then((r) => r.data);

const fetchUsers = (q: string) =>
  api
    .get<AdminUserRow[]>("/admin/users", { params: q ? { q } : undefined })
    .then((r) => r.data);

export function NotificationsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [audience, setAudience] = useState<Audience>("all");
  const [targetId, setTargetId] = useState("");
  const [targetCity, setTargetCity] = useState("");
  const [userQuery, setUserQuery] = useState("");

  const { data } = useQuery({
    queryKey: ["push"],
    queryFn: async () =>
      (await api.get<PushNotification[]>("/admin/push")).data,
  });

  const { data: status } = useQuery({
    queryKey: ["push", "status"],
    queryFn: async () => (await api.get<PushStatus>("/admin/push/status")).data,
  });

  const { data: courses = [] } = useQuery({
    queryKey: ["admin", "courses"],
    queryFn: fetchCourses,
  });

  const { data: users = [] } = useQuery({
    queryKey: ["admin", "users", userQuery],
    queryFn: () => fetchUsers(userQuery),
    enabled: audience === "user",
  });

  const { data: cities = [] } = useQuery({
    queryKey: ["admin", "clients", "cities"],
    queryFn: async () => (await api.get<string[]>("/admin/clients/cities")).data,
    enabled: audience === "city",
  });

  const send = useMutation({
    mutationFn: () =>
      api.post("/admin/push", {
        title,
        body,
        audience,
        target_id: audience === "user" || audience === "course" ? targetId : null,
        target_city: audience === "city" ? targetCity : null,
      }),
    onSuccess: () => {
      setTitle("");
      setBody("");
      setTargetId("");
      setTargetCity("");
      toast.success(t.notifications.sent);
      qc.invalidateQueries({ queryKey: ["push"] });
      qc.invalidateQueries({ queryKey: ["push", "status"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const sendTest = useMutation({
    mutationFn: () =>
      api.post("/admin/push/test", {
        title: "🧪 Test xabar",
        body: "NotiqAI push testi muvaffaqiyatli ✅",
        audience: "user",
        target_id: null, // → server sends to current admin's own tokens
      }),
    onSuccess: () => {
      toast.success("Test xabar yuborildi.");
      qc.invalidateQueries({ queryKey: ["push"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleSend() {
    const ok = await confirm({
      title: audience === "all"
        ? "Barcha foydalanuvchilarga xabar yuborishni tasdiqlaysizmi?"
        : audience === "course"
          ? "Tanlangan kursga xabar yuborishni tasdiqlaysizmi?"
          : audience === "city"
            ? `"${targetCity}" shahridagi foydalanuvchilarga xabar yuborishni tasdiqlaysizmi?`
            : "Tanlangan foydalanuvchiga xabar yuborishni tasdiqlaysizmi?",
      description: title,
      variant: "primary",
      confirmText: t.modal.send,
    });
    if (ok) send.mutate();
  }

  async function handleTestSend() {
    const ok = await confirm({
      title: "Test xabar yuborishni tasdiqlaysizmi?",
      variant: "primary",
      confirmText: t.modal.send,
    });
    if (ok) sendTest.mutate();
  }

  const audienceLabel = (a: PushNotification["audience"]) => {
    if (a === "course") return "Kursga";
    if (a === "user") return "Bitta foydalanuvchiga";
    if (a === "city") return "Shaharga";
    return "Hammaga";
  };

  const ready =
    !!title &&
    !!body &&
    !send.isPending &&
    (audience === "all" ||
      ((audience === "user" || audience === "course") && !!targetId) ||
      (audience === "city" && !!targetCity));

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader title={t.notifications.title} subtitle={t.notifications.subtitle} />

      <FcmStatusBanner status={status} onTestPush={handleTestSend} testing={sendTest.isPending} />

      <div className="mt-6 grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-line bg-card p-6">
          <h2 className="mb-4 font-bold">Yangi xabar</h2>

          <div className="mb-3">
            <SegmentedControl
              className="w-full"
              value={audience}
              onChange={(a) => {
                setAudience(a);
                setTargetId("");
                setTargetCity("");
              }}
              options={(["all", "course", "user", "city"] as Audience[]).map((a) => ({
                value: a,
                label:
                  a === "all"
                    ? "Hammaga"
                    : a === "course"
                      ? "Kursga"
                      : a === "city"
                        ? "Shaharga"
                        : "Foydalanuvchiga",
              }))}
            />
          </div>

          {audience === "course" && (
            <GlassSelect
              value={targetId}
              onChange={(e) => setTargetId(e.target.value)}
              className="mb-3"
            >
              <option value="">— Kursni tanlang —</option>
              {courses.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </GlassSelect>
          )}

          {audience === "city" && (
            <GlassSelect
              value={targetCity}
              onChange={(e) => setTargetCity(e.target.value)}
              className="mb-3"
            >
              <option value="">— Shaharni tanlang —</option>
              {cities.map((city) => (
                <option key={city} value={city}>
                  {city}
                </option>
              ))}
            </GlassSelect>
          )}

          {audience === "user" && (
            <div className="mb-3 space-y-2">
              <GlassInput
                value={userQuery}
                onChange={(e) => setUserQuery(e.target.value)}
                placeholder="Telefon, ism yoki email boʻyicha qidirish…"
              />
              <GlassSelect
                value={targetId}
                onChange={(e) => setTargetId(e.target.value)}
              >
                <option value="">— Foydalanuvchini tanlang —</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.full_name || u.phone || u.email || u.id.slice(0, 8)}
                    {u.phone ? ` · ${u.phone}` : ""}
                  </option>
                ))}
              </GlassSelect>
            </div>
          )}

          <GlassInput
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={t.notifications.titleField}
            className="mb-3"
          />
          <GlassTextarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder={t.notifications.body}
            rows={5}
            className="mb-4"
          />
          <PrimaryButton
            disabled={!ready}
            loading={send.isPending}
            onClick={handleSend}
            className="w-full py-3"
          >
            {send.isPending ? (
              <Loader2 size={16} className="animate-spin" />
            ) : (
              <Send size={15} />
            )}
            {send.isPending
              ? "Yuborilmoqda…"
              : audience === "all"
                ? "Hammaga yuborish"
                : audience === "course"
                  ? "Kursga yuborish"
                  : "Yuborish"}
          </PrimaryButton>
          {send.isError && (
            <p className="mt-2 text-sm text-red-600">{apiError(send.error)}</p>
          )}
          {send.isSuccess && (
            <p className="mt-2 text-sm text-green-600">
              Yuborildi ✓ ({send.data?.data?.delivered_count ?? 0} ta qurilma)
            </p>
          )}
        </div>

        <div className="rounded-2xl border border-line bg-card p-6">
          <h2 className="mb-4 font-bold">Yuborilgan xabarlar</h2>
          <div className="space-y-3">
            {data?.length === 0 && (
              <p className="text-muted">Hali xabar yuborilmagan.</p>
            )}
            {data?.map((n, i) => (
              <Reveal key={n.id} index={i}>
                <div className="rounded-xl border border-line p-4">
                  <div className="flex items-center justify-between gap-2">
                    <h3 className="font-semibold text-ink">{n.title}</h3>
                    <StatusPill tone="neutral" className="shrink-0">
                      {audienceLabel(n.audience)}
                    </StatusPill>
                  </div>
                  <p className="mt-1 text-sm text-muted">{n.body}</p>
                  <div className="mt-2 flex items-center justify-between text-xs text-muted">
                    <span>{n.delivered_count ?? 0} ta qurilmaga yetib borgan</span>
                    <span>
                      {n.sent_at ? new Date(n.sent_at).toLocaleString() : "—"}
                    </span>
                  </div>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function FcmStatusBanner({
  status,
  onTestPush,
  testing,
}: {
  status: PushStatus | undefined;
  onTestPush: () => void;
  testing: boolean;
}) {
  if (!status) return null;
  const ok = status.configured;
  return (
    <div
      className={`mt-4 flex flex-wrap items-start gap-4 rounded-2xl border p-4 ${
        ok
          ? "border-green-200 bg-green-50"
          : "border-amber-200 bg-amber-50"
      }`}
    >
      <div className="shrink-0 pt-0.5">
        {ok ? (
          <CheckCircle2 size={20} className="text-green-600 dark:text-green-400" />
        ) : (
          <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" />
        )}
      </div>
      <div className="min-w-0 flex-1">
        <h3
          className={`text-sm font-extrabold ${
            ok ? "text-green-900" : "text-amber-900"
          }`}
        >
          {ok
            ? "FCM tayyor — push xabarlari qurilmalarga yetib boradi"
            : "FCM sozlanmagan — push xabarlari faqat DB'ga yoziladi, qurilmaga BORMAYDI"}
        </h3>
        <div
          className={`mt-1 grid grid-cols-2 gap-x-4 gap-y-1 text-xs sm:grid-cols-4 ${
            ok ? "text-green-800" : "text-amber-800"
          }`}
        >
          <div>
            <span className="opacity-70">FCM yoqilgan:</span>{" "}
            <b>{status.enabled ? "ha" : "yoʻq"}</b>
          </div>
          <div>
            <span className="opacity-70">Service account:</span>{" "}
            <b>{status.service_account_exists ? "mavjud" : "topilmadi"}</b>
          </div>
          <div>
            <span className="opacity-70">Roʻyxatdan oʻtgan tokenlar:</span>{" "}
            <b>{status.registered_tokens}</b>
          </div>
          <div>
            <span className="opacity-70">Project:</span>{" "}
            <b>{status.project_id ?? "—"}</b>
          </div>
        </div>
        {!ok && status.last_error && (
          <p
            className={`mt-2 text-xs ${
              ok ? "text-green-700" : "text-amber-700"
            }`}
          >
            <b>Sabab:</b> {status.last_error}
          </p>
        )}
        <p
          className={`mt-1 text-xs ${
            ok ? "text-green-700" : "text-amber-700"
          }`}
        >
          {status.hint}
        </p>
      </div>
      <button
        type="button"
        disabled={testing || status.registered_tokens === 0}
        onClick={onTestPush}
        className={`press flex shrink-0 items-center gap-2 rounded-full px-4 py-2 text-xs font-bold transition disabled:opacity-50 ${
          ok
            ? "bg-green-600 text-white hover:bg-green-700"
            : "bg-amber-600 text-white hover:bg-amber-700"
        }`}
      >
        {testing ? (
          <Loader2 size={14} className="animate-spin" />
        ) : (
          <FlaskConical size={14} />
        )}
        Test push
      </button>
    </div>
  );
}
