import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  UserCog,
  Mail,
  Lock,
  Trash2,
  Power,
  Edit3,
  X,
  Check,
} from "lucide-react";
import { api, apiError } from "../lib/api";
import type { Curator } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

export function CuratorsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<Curator | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["admin", "curators"],
    queryFn: async () => (await api.get<Curator[]>("/admin/curators")).data,
  });

  const toggleActive = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) =>
      api.patch(`/admin/curators/${id}`, { is_active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "curators"] }),
  });

  const hardDelete = useMutation({
    mutationFn: (id: string) =>
      api.delete(`/admin/curators/${id}`, { params: { force: true } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "curators"] }),
  });

  return (
    <div className="p-8">
      <PageHeader
        title={t.curators.title}
        subtitle={t.curators.subtitle}
        actions={
          <button
            onClick={() => setShowCreate((v) => !v)}
            className="flex items-center gap-2 rounded-xl bg-wine px-5 py-2.5 text-sm font-bold text-white hover:bg-wine-dark"
          >
            <Plus size={16} />
            {t.curators.addBtn}
          </button>
        }
      />

      {showCreate && (
        <CreateCuratorForm
          onDone={() => setShowCreate(false)}
          onSuccess={() => {
            setShowCreate(false);
            qc.invalidateQueries({ queryKey: ["admin", "curators"] });
          }}
        />
      )}

      {editing && (
        <EditCuratorForm
          curator={editing}
          onDone={() => setEditing(null)}
          onSuccess={() => {
            setEditing(null);
            qc.invalidateQueries({ queryKey: ["admin", "curators"] });
          }}
        />
      )}

      {isLoading && <p className="text-muted">{t.common.loading}</p>}
      {isError && (
        <p className="rounded-xl bg-red-50 p-4 text-red-700 dark:bg-red-900/20 dark:text-red-400">
          {t.curators.loadError}
        </p>
      )}

      {data && data.length === 0 && !isLoading && (
        <p className="rounded-xl border border-line bg-card p-6 text-muted">
          {t.curators.noCurators}
        </p>
      )}

      <div className="space-y-3">
        {data?.map((c) => (
          <div
            key={c.id}
            className={`flex items-center gap-4 rounded-2xl border bg-card p-4 ${
              c.is_active ? "border-line" : "border-red-200 bg-red-50/30"
            }`}
          >
            <div
              className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl text-sm font-black ${
                c.is_active
                  ? "bg-wine text-white"
                  : "bg-gray-200 text-gray-500"
              }`}
            >
              <UserCog size={20} />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-bold text-ink truncate">
                  {c.full_name ?? "Nomsiz kurator"}
                </span>
                <span
                  className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                    c.is_active
                      ? "bg-green-100 text-green-700"
                      : "bg-red-100 text-red-600"
                  }`}
                >
                  {c.is_active ? "Faol" : "Bloklangan"}
                </span>
              </div>
              <div className="mt-0.5 flex items-center gap-1 text-xs text-muted">
                <Mail size={12} />
                {c.email}
              </div>
              <div className="mt-0.5 text-xs text-muted">
                Qo'shilgan: {new Date(c.created_at).toLocaleDateString()}
              </div>
            </div>

            <div className="flex items-center gap-1.5 shrink-0">
              <button
                title={t.common.edit}
                onClick={() => setEditing(c)}
                className="rounded-lg p-2 text-muted hover:bg-wine-50"
              >
                <Edit3 size={15} />
              </button>
              <button
                title={c.is_active ? t.curators.block : t.curators.activate}
                onClick={() =>
                  toggleActive.mutate({ id: c.id, is_active: !c.is_active })
                }
                disabled={toggleActive.isPending}
                className={`rounded-lg p-2 hover:bg-wine-50 disabled:opacity-50 ${
                  c.is_active ? "text-amber-600" : "text-green-600"
                }`}
              >
                <Power size={15} />
              </button>
              <button
                title={t.common.delete}
                onClick={() => {
                  if (
                    confirm(
                      t.curators.confirmDelete(c.full_name ?? c.email ?? ""),
                    )
                  ) {
                    hardDelete.mutate(c.id);
                  }
                }}
                disabled={hardDelete.isPending}
                className="rounded-lg p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 disabled:opacity-50"
              >
                <Trash2 size={15} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Create curator form ─────────────────────────────────────────────────────

function CreateCuratorForm({
  onDone,
  onSuccess,
}: {
  onDone: () => void;
  onSuccess: () => void;
}) {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [emailError, setEmailError] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () =>
      api.post("/admin/curators", {
        full_name: fullName.trim(),
        email: email.trim(),
        password,
      }),
    onSuccess,
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setEmailError(null);
    if (!email.toLowerCase().trim().endsWith("@najotnur.uz")) {
      setEmailError("Email @najotnur.uz bilan tugashi kerak.");
      return;
    }
    create.mutate();
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mb-6 rounded-2xl border border-wine/20 bg-wine/5 p-5"
    >
      <div className="mb-4 flex items-center justify-between">
        <h2 className="font-bold text-ink">Yangi kurator qo'shish</h2>
        <button
          type="button"
          onClick={onDone}
          className="rounded-lg p-1 text-muted hover:bg-card/50"
        >
          <X size={16} />
        </button>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <label className="text-sm">
          <span className="mb-1 block font-semibold text-ink">F.I.O.</span>
          <input
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="Masalan: Aliyev Ali"
            className="w-full rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-wine"
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-semibold text-ink">Email</span>
          <input
            required
            type="email"
            value={email}
            onChange={(e) => { setEmail(e.target.value); setEmailError(null); }}
            placeholder="curator@najotnur.uz"
            className={`w-full rounded-lg border px-3 py-2 text-sm outline-none focus:border-wine ${emailError ? "border-red-400" : "border-line"}`}
          />
          {emailError && <p className="mt-1 text-xs text-red-600">{emailError}</p>}
        </label>
        <label className="text-sm sm:col-span-2">
          <span className="mb-1 block font-semibold text-ink">
            Parol (kamida 6 belgi)
          </span>
          <input
            required
            type="password"
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-wine"
          />
        </label>
      </div>

      {create.isError && (
        <p className="mt-2 text-sm text-red-600">{apiError(create.error)}</p>
      )}

      <div className="mt-4 flex gap-2">
        <button
          type="submit"
          disabled={create.isPending}
          className="flex items-center gap-2 rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
        >
          <Check size={14} />
          {create.isPending ? "Saqlanmoqda…" : "Qo'shish"}
        </button>
        <button
          type="button"
          onClick={onDone}
          className="rounded-lg border border-line px-5 py-2 text-sm font-semibold text-ink"
        >
          Bekor qilish
        </button>
      </div>
    </form>
  );
}

// ─── Edit curator form ───────────────────────────────────────────────────────

function EditCuratorForm({
  curator,
  onDone,
  onSuccess,
}: {
  curator: Curator;
  onDone: () => void;
  onSuccess: () => void;
}) {
  const [fullName, setFullName] = useState(curator.full_name ?? "");
  const [password, setPassword] = useState("");
  const [isActive, setIsActive] = useState(curator.is_active);

  const update = useMutation({
    mutationFn: () => {
      const body: Record<string, unknown> = {
        full_name: fullName.trim(),
        is_active: isActive,
      };
      if (password) body.password = password;
      return api.patch(`/admin/curators/${curator.id}`, body);
    },
    onSuccess,
  });

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        update.mutate();
      }}
      className="mb-6 rounded-2xl border border-wine/20 bg-wine/5 p-5"
    >
      <div className="mb-4 flex items-center justify-between">
        <h2 className="font-bold text-ink">Kuratorni tahrirlash</h2>
        <button
          type="button"
          onClick={onDone}
          className="rounded-lg p-1 text-muted hover:bg-card/50"
        >
          <X size={16} />
        </button>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <label className="text-sm">
          <span className="mb-1 block font-semibold text-ink">F.I.O.</span>
          <input
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="w-full rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-wine"
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-semibold text-ink">Email</span>
          <input
            disabled
            value={curator.email ?? ""}
            className="w-full cursor-not-allowed rounded-lg border border-line bg-gray-50 px-3 py-2 text-sm text-muted"
          />
        </label>
        <label className="text-sm sm:col-span-2">
          <span className="mb-1 block font-semibold text-ink">
            Yangi parol (ixtiyoriy)
          </span>
          <div className="flex items-center gap-2">
            <Lock size={14} className="text-muted" />
            <input
              type="password"
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="O'zgartirmasangiz bo'sh qoldiring"
              className="flex-1 rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-wine"
            />
          </div>
        </label>
        <label className="flex items-center gap-2 text-sm sm:col-span-2">
          <input
            type="checkbox"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
            className="accent-wine"
          />
          Faol (tizimga kirishi mumkin)
        </label>
      </div>

      {update.isError && (
        <p className="mt-2 text-sm text-red-600">{apiError(update.error)}</p>
      )}

      <div className="mt-4 flex gap-2">
        <button
          type="submit"
          disabled={update.isPending}
          className="flex items-center gap-2 rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
        >
          <Check size={14} />
          {update.isPending ? "Saqlanmoqda…" : "Saqlash"}
        </button>
        <button
          type="button"
          onClick={onDone}
          className="rounded-lg border border-line px-5 py-2 text-sm font-semibold text-ink"
        >
          Bekor qilish
        </button>
      </div>
    </form>
  );
}
