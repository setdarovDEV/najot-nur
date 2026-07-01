import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  UserCog,
  Mail,
  Lock,
  Trash2,
  Power,
  Edit3,
} from "lucide-react";
import { api, apiError } from "../lib/api";
import type { Curator } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import { Modal, ModalFooter } from "../components/Modal";


export function CuratorsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const confirm = useConfirm();
  const toast = useToast();
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<Curator | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["admin", "curators"],
    queryFn: async () => (await api.get<Curator[]>("/admin/curators")).data,
  });

  const toggleActive = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) =>
      api.patch(`/admin/curators/${id}`, { is_active }),
    onSuccess: () => {
      toast.success(t.curators.toggleSuccess);
      qc.invalidateQueries({ queryKey: ["admin", "curators"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const hardDelete = useMutation({
    mutationFn: (id: string) =>
      api.delete(`/admin/curators/${id}`, { params: { force: true } }),
    onSuccess: () => {
      toast.success(t.curators.deleteSuccess);
      qc.invalidateQueries({ queryKey: ["admin", "curators"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  return (
    <div className="p-8">
      <PageHeader
        title={t.curators.title}
        subtitle={t.curators.subtitle}
        actions={
          <button
            onClick={() => setShowCreate(true)}
            className="flex items-center gap-2 rounded-xl bg-wine px-5 py-2.5 text-sm font-bold text-white hover:bg-wine-dark"
          >
            <Plus size={16} />
            {t.curators.addBtn}
          </button>
        }
      />

      <CreateCuratorForm
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onSuccess={() => {
          qc.invalidateQueries({ queryKey: ["admin", "curators"] });
        }}
      />

      <EditCuratorForm
        open={!!editing}
        curator={editing}
        onClose={() => setEditing(null)}
        onSuccess={() => {
          qc.invalidateQueries({ queryKey: ["admin", "curators"] });
        }}
      />

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
                      ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                      : "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400"
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
                className="rounded-lg p-2 text-muted hover:bg-wine-50 dark:hover:bg-wine-900/20"
              >
                <Edit3 size={15} />
              </button>
              <button
                title={c.is_active ? t.curators.block : t.curators.activate}
                onClick={async () => {
                  const ok = await confirm({
                    title: c.is_active
                      ? t.curators.confirmBlock(c.full_name ?? c.email ?? "")
                      : t.curators.confirmActivate(c.full_name ?? c.email ?? ""),
                    variant: c.is_active ? "warning" : "primary",
                    confirmText: c.is_active ? t.modal.block : t.modal.activate,
                  });
                  if (ok)
                    toggleActive.mutate({ id: c.id, is_active: !c.is_active });
                }}
                disabled={toggleActive.isPending}
                className={`rounded-lg p-2 hover:bg-wine-50 dark:hover:bg-wine-900/20 disabled:opacity-50 ${
                  c.is_active ? "text-amber-600 dark:text-amber-400" : "text-green-600 dark:text-green-400"
                }`}
              >
                <Power size={15} />
              </button>
              <button
                title={t.common.delete}
                onClick={async () => {
                  const ok = await confirm({
                    title: t.curators.confirmDelete(
                      c.full_name ?? c.email ?? "",
                    ),
                    description: t.modal.deleteDesc(
                      "kurator",
                      c.full_name ?? c.email ?? "",
                    ),
                    variant: "danger",
                    confirmText: t.modal.delete,
                  });
                  if (ok) hardDelete.mutate(c.id);
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

// ─── Create curator form (Modal) ────────────────────────────────────────────

function CreateCuratorForm({
  open,
  onClose,
  onSuccess,
}: {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const { t } = useLang();
  const confirm = useConfirm();
  const toast = useToast();
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
    onSuccess: () => {
      toast.success(t.curators.createSuccess);
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleSubmit() {
    setEmailError(null);
    if (!email.toLowerCase().trim().endsWith("@najotnur.uz")) {
      setEmailError("Email @najotnur.uz bilan tugashi kerak.");
      return;
    }
    const ok = await confirm({
      title: t.modal.createTitle("kurator"),
      description: t.modal.createDesc("Kurator"),
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (ok) create.mutate();
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Yangi kurator qo'shish"
      subtitle="Platformaga yangi kurator qo'shing"
      size="md"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={handleSubmit}
          saving={create.isPending}
          submitLabel={create.isPending ? "Saqlanmoqda…" : "Qo'shish"}
        />
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            F.I.O. *
          </label>
          <input
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="Masalan: Aliyev Ali"
            className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            Email *
          </label>
          <input
            type="email"
            value={email}
            onChange={(e) => { setEmail(e.target.value); setEmailError(null); }}
            placeholder="curator@najotnur.uz"
            className={`w-full rounded-xl border bg-card px-4 py-2.5 text-sm text-ink outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10 ${
              emailError ? "border-red-400" : "border-line"
            }`}
          />
          {emailError && (
            <p className="mt-1 text-xs text-red-600 dark:text-red-400">
              {emailError}
            </p>
          )}
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            Parol (kamida 6 belgi) *
          </label>
          <input
            type="password"
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
          />
        </div>
        {create.isError && (
          <p className="sm:col-span-2 text-sm text-red-600 dark:text-red-400">
            {apiError(create.error)}
          </p>
        )}
      </div>
    </Modal>
  );
}

// ─── Edit curator form (Modal) ───────────────────────────────────────────────

function EditCuratorForm({
  open,
  curator,
  onClose,
  onSuccess,
}: {
  open: boolean;
  curator: Curator | null;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const { t } = useLang();
  const confirm = useConfirm();
  const toast = useToast();
  const [fullName, setFullName] = useState(curator?.full_name ?? "");
  const [password, setPassword] = useState("");
  const [isActive, setIsActive] = useState(curator?.is_active ?? true);

  // Re-sync when modal opens with a new curator
  useEffect(() => {
    if (curator) {
      setFullName(curator.full_name ?? "");
      setPassword("");
      setIsActive(curator.is_active);
    }
  }, [curator]);

  const update = useMutation({
    mutationFn: () => {
      const body: Record<string, unknown> = {
        full_name: fullName.trim(),
        is_active: isActive,
      };
      if (password) body.password = password;
      return api.patch(`/admin/curators/${curator!.id}`, body);
    },
    onSuccess: () => {
      toast.success(t.curators.updateSuccess);
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleSubmit() {
    const ok = await confirm({
      title: t.modal.updateTitle("Kurator"),
      description: t.modal.updateDesc("Kurator"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (ok) update.mutate();
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Kuratorni tahrirlash"
      subtitle="Kurator ma'lumotlarini yangilang"
      size="md"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={handleSubmit}
          saving={update.isPending}
          submitLabel={update.isPending ? "Saqlanmoqda…" : "Saqlash"}
        />
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            F.I.O. *
          </label>
          <input
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            Email
          </label>
          <input
            disabled
            value={curator?.email ?? ""}
            className="w-full cursor-not-allowed rounded-xl border border-line bg-surface px-4 py-2.5 text-sm text-muted"
          />
        </div>
        <div className="sm:col-span-2">
          <label className="mb-1.5 block flex items-center gap-1.5 text-xs font-bold text-muted uppercase tracking-wide">
            <Lock size={12} />
            Yangi parol (ixtiyoriy)
          </label>
          <input
            type="password"
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="O'zgartirmasangiz bo'sh qoldiring"
            className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
          />
        </div>
        <label className="flex cursor-pointer items-center gap-3 sm:col-span-2">
          <div
            onClick={() => setIsActive((v) => !v)}
            className={`relative h-6 w-11 rounded-full transition ${
              isActive ? "bg-wine" : "bg-line"
            }`}
          >
            <div
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${
                isActive ? "left-5" : "left-0.5"
              }`}
            />
          </div>
          <span className="text-sm font-semibold text-ink">
            Faol (tizimga kirishi mumkin)
          </span>
        </label>
        {update.isError && (
          <p className="sm:col-span-2 text-sm text-red-600 dark:text-red-400">
            {apiError(update.error)}
          </p>
        )}
      </div>
    </Modal>
  );
}
