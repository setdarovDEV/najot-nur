import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, CheckCircle2, FlaskConical, Loader2, Send } from "lucide-react";
import { api, apiError } from "../lib/api";
import type { AdminCourse, PushNotification, PushStatus } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

type Audience = "all" | "course" | "user";

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
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [audience, setAudience] = useState<Audience>("all");
  const [targetId, setTargetId] = useState("");
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

  const send = useMutation({
    mutationFn: () =>
      api.post("/admin/push", {
        title,
        body,
        audience,
        target_id: audience === "all" ? null : targetId,
      }),
    onSuccess: () => {
      setTitle("");
      setBody("");
      setTargetId("");
      qc.invalidateQueries({ queryKey: ["push"] });
      qc.invalidateQueries({ queryKey: ["push", "status"] });
    },
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
      qc.invalidateQueries({ queryKey: ["push"] });
    },
  });

  const audienceLabel = (a: PushNotification["audience"]) => {
    if (a === "course") return "Kursga";
    if (a === "user") return "Bitta foydalanuvchiga";
    return "Hammaga";
  };

  const ready =
    !!title &&
    !!body &&
    !send.isPending &&
    (audience === "all" || !!targetId);

  return (
    <div className="p-8">
      <PageHeader title={t.notifications.title} subtitle={t.notifications.subtitle} />

      <FcmStatusBanner status={status} onTestPush={() => sendTest.mutate()} testing={sendTest.isPending} />

      <div className="mt-6 grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-line bg-card p-6">
          <h2 className="mb-4 font-bold">Yangi xabar</h2>

          <div className="mb-3 flex gap-2">
            {(["all", "course", "user"] as Audience[]).map((a) => (
              <button
                key={a}
                type="button"
                onClick={() => {
                  setAudience(a);
                  setTargetId("");
                }}
                className={`flex-1 rounded-lg border px-3 py-2 text-sm font-semibold transition ${
                  audience === a
                    ? "border-wine bg-wine text-white"
                    : "border-line bg-card text-ink hover:border-wine/40"
                }`}
              >
                {a === "all"
                  ? "Hammaga"
                  : a === "course"
                    ? "Kursga"
                    : "Foydalanuvchiga"}
              </button>
            ))}
          </div>

          {audience === "course" && (
            <select
              value={targetId}
              onChange={(e) => setTargetId(e.target.value)}
              className="mb-3 w-full rounded-lg border border-line px-4 py-2.5 outline-none focus:border-wine"
            >
              <option value="">— Kursni tanlang —</option>
              {courses.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </select>
          )}

          {audience === "user" && (
            <div className="mb-3 space-y-2">
              <input
                value={userQuery}
                onChange={(e) => setUserQuery(e.target.value)}
                placeholder="Telefon, ism yoki email boʻyicha qidirish…"
                className="w-full rounded-lg border border-line px-4 py-2.5 outline-none focus:border-wine"
              />
              <select
                value={targetId}
                onChange={(e) => setTargetId(e.target.value)}
                className="w-full rounded-lg border border-line px-4 py-2.5 outline-none focus:border-wine"
              >
                <option value="">— Foydalanuvchini tanlang —</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.full_name || u.phone || u.email || u.id.slice(0, 8)}
                    {u.phone ? ` · ${u.phone}` : ""}
                  </option>
                ))}
              </select>
            </div>
          )}

          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={t.notifications.titleField}
            className="mb-3 w-full rounded-lg border border-line bg-card px-4 py-2.5 text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
          />
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder={t.notifications.body}
            rows={5}
            className="mb-4 w-full rounded-lg border border-line bg-card px-4 py-2.5 text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
          />
          <button
            disabled={!ready}
            onClick={() => send.mutate()}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-wine py-3 font-bold text-white hover:bg-wine-dark disabled:opacity-60"
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
          </button>
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
            {data?.map((n) => (
              <div
                key={n.id}
                className="rounded-xl border border-line p-4"
              >
                <div className="flex items-center justify-between gap-2">
                  <h3 className="font-semibold text-ink">{n.title}</h3>
                  <span className="shrink-0 rounded-full bg-wine/10 px-2 py-0.5 text-[10px] font-bold text-wine">
                    {audienceLabel(n.audience)}
                  </span>
                </div>
                <p className="mt-1 text-sm text-muted">{n.body}</p>
                <div className="mt-2 flex items-center justify-between text-xs text-muted">
                  <span>{n.delivered_count ?? 0} ta qurilmaga yetib borgan</span>
                  <span>
                    {n.sent_at ? new Date(n.sent_at).toLocaleString() : "—"}
                  </span>
                </div>
              </div>
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
          <CheckCircle2 size={20} className="text-green-600" />
        ) : (
          <AlertTriangle size={20} className="text-amber-600" />
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
        className={`flex shrink-0 items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition disabled:opacity-50 ${
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
