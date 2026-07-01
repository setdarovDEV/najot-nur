import { useCallback, useEffect, useRef, useState } from "react";
import {
  Check,
  ChevronDown,
  ChevronUp,
  Edit2,
  Headphones,
  Mic,
  Play,
  Plus,
  Trash2,
  Upload,
  X,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { useAuth } from "../lib/auth";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import { Modal, ModalFooter } from "../components/Modal";

interface Practicum {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  expert_text: string | null;
  expert_audio_url: string | null;
  is_free: boolean;
  price: number;
  status: "draft" | "approved" | "rejected";
  created_at: string;
}

type FilterKey = "all" | "draft" | "approved" | "rejected" | "free" | "paid";

const STATUS_COLOR: Record<string, string> = {
  draft: "bg-yellow-100 text-yellow-700",
  approved: "bg-green-100 text-green-700",
  rejected: "bg-red-100 text-red-700",
};

function formatPrice(price: number) {
  return price.toLocaleString("uz-UZ") + " so'm";
}

export function PracticumsPage() {
  const { role } = useAuth();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const p = t.practicums;
  const isAdmin = role === "admin";

  const [practicums, setPracticums] = useState<Practicum[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [editTarget, setEditTarget] = useState<Practicum | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [filter, setFilter] = useState<FilterKey>("all");

  const fetchPracticums = useCallback(async () => {
    try {
      const endpoint = isAdmin ? "/practicums/admin/all" : "/practicums/my/drafts";
      const { data } = await api.get<Practicum[]>(endpoint);
      setPracticums(data);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  }, [isAdmin]);

  useEffect(() => { fetchPracticums(); }, [fetchPracticums]);

  const approve = async (pr: Practicum) => {
    const ok = await confirm({
      title: p.confirmApprove(pr.title),
      variant: "primary",
      confirmText: t.modal.approve,
    });
    if (!ok) return;
    try {
      await api.patch(`/practicums/admin/${pr.id}/approve`);
      setPracticums((prev) =>
        prev.map((x) => x.id === pr.id ? { ...x, status: "approved" } : x)
      );
      toast.success(p.approveSuccess);
    } catch (e) {
      toast.error(apiError(e));
    }
  };

  const reject = async (pr: Practicum) => {
    const ok = await confirm({
      title: p.confirmReject(pr.title),
      variant: "danger",
      confirmText: t.modal.reject,
    });
    if (!ok) return;
    try {
      await api.patch(`/practicums/admin/${pr.id}/reject`);
      setPracticums((prev) =>
        prev.map((x) => x.id === pr.id ? { ...x, status: "rejected" } : x)
      );
      toast.success(p.rejectSuccess);
    } catch (e) {
      toast.error(apiError(e));
    }
  };

  const deletePracticum = async (pr: Practicum) => {
    const ok = await confirm({
      title: p.confirmDelete(pr.title),
      description: t.modal.deleteDesc("praktikum", pr.title),
      variant: "danger",
      confirmText: t.modal.delete,
    });
    if (!ok) return;
    try {
      await api.delete(`/practicums/${pr.id}`);
      setPracticums((prev) => prev.filter((x) => x.id !== pr.id));
      if (expandedId === pr.id) setExpandedId(null);
      toast.success(p.deleteSuccess);
    } catch (e) {
      toast.error(apiError(e));
    }
  };

  const filtered = practicums.filter((pr) => {
    if (filter === "all") return true;
    if (filter === "free") return pr.is_free;
    if (filter === "paid") return !pr.is_free;
    return pr.status === filter;
  });

  const counts = {
    all: practicums.length,
    draft: practicums.filter((p) => p.status === "draft").length,
    approved: practicums.filter((p) => p.status === "approved").length,
    rejected: practicums.filter((p) => p.status === "rejected").length,
    free: practicums.filter((p) => p.is_free).length,
    paid: practicums.filter((p) => !p.is_free).length,
  };

  const filters: { key: FilterKey; label: string }[] = [
    { key: "all", label: `Hammasi (${counts.all})` },
    { key: "draft", label: `Kutilmoqda (${counts.draft})` },
    { key: "approved", label: `Tasdiqlangan (${counts.approved})` },
    { key: "rejected", label: `Rad etilgan (${counts.rejected})` },
    { key: "free", label: `Bepul (${counts.free})` },
    { key: "paid", label: `Pullik (${counts.paid})` },
  ];

  return (
    <div className="p-6 md:p-8">
      <PageHeader
        title={p.title}
        subtitle={
          isAdmin
            ? `${counts.draft} ta praktikum tasdiqlash kutilmoqda`
            : p.subtitle
        }
        actions={
          !isAdmin && (
            <button
              onClick={() => setShowCreate(true)}
              className="flex items-center gap-2 rounded-xl bg-wine px-4 py-2.5 text-sm font-bold text-white transition hover:bg-wine-dark"
            >
              <Plus size={16} />
              {p.addBtn}
            </button>
          )
        }
      />

      {/* Stats cards - admin only */}
      {isAdmin && !loading && (
        <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <StatCard label="Jami" value={counts.all} color="wine" />
          <StatCard label="Kutilmoqda" value={counts.draft} color="yellow" />
          <StatCard label="Tasdiqlangan" value={counts.approved} color="green" />
          <StatCard label="Bepul" value={counts.free} color="blue" />
        </div>
      )}

      {/* Filter bar */}
      {!loading && practicums.length > 0 && (
        <div className="mb-4 flex flex-wrap gap-2">
          {filters.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition-all ${
                filter === f.key
                  ? "bg-wine text-white shadow-sm"
                  : "border border-line bg-card text-muted hover:border-wine/30 hover:text-wine"
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      )}

      {loading ? (
        <div className="flex h-48 items-center justify-center">
          <div className="flex items-center gap-3 text-muted">
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-wine border-t-transparent" />
            Yuklanmoqda…
          </div>
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          isEmpty={practicums.length === 0}
          onAdd={() => setShowCreate(true)}
          isAdmin={isAdmin}
          p={p}
        />
      ) : (
        <div className="space-y-3">
          {filtered.map((pr) => (
            <PracticumCard
              key={pr.id}
              practicum={pr}
              isAdmin={isAdmin}
              isExpanded={expandedId === pr.id}
              onToggle={() => setExpandedId(expandedId === pr.id ? null : pr.id)}
              onApprove={() => approve(pr)}
              onReject={() => reject(pr)}
              onEdit={() => setEditTarget(pr)}
              onDelete={() => deletePracticum(pr)}
              onAudioUploaded={(updated) =>
                setPracticums((prev) =>
                  prev.map((x) => x.id === updated.id ? updated : x)
                )
              }
            />
          ))}
        </div>
      )}

      {showCreate && (
        <CreatePracticumModal
          onClose={() => setShowCreate(false)}
          onCreated={() => { setShowCreate(false); fetchPracticums(); }}
        />
      )}

      {editTarget && (
        <EditPracticumModal
          practicum={editTarget}
          onClose={() => setEditTarget(null)}
          onSaved={(updated) => {
            setPracticums((prev) =>
              prev.map((x) => x.id === updated.id ? updated : x)
            );
            setEditTarget(null);
          }}
        />
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  color,
}: {
  label: string;
  value: number;
  color: "wine" | "yellow" | "green" | "blue";
}) {
  const colors = {
    wine: "border-wine/20 bg-wine/5 text-wine",
    yellow: "border-yellow-200 bg-yellow-50 text-yellow-700",
    green: "border-green-200 bg-green-50 text-green-700",
    blue: "border-blue-200 bg-blue-50 text-blue-700",
  };
  return (
    <div className={`rounded-2xl border p-4 ${colors[color]}`}>
      <div className="text-2xl font-black">{value}</div>
      <div className="mt-0.5 text-xs font-semibold opacity-80">{label}</div>
    </div>
  );
}

function EmptyState({
  isEmpty,
  onAdd,
  isAdmin,
  p,
}: {
  isEmpty: boolean;
  onAdd: () => void;
  isAdmin: boolean;
  p: ReturnType<typeof useLang>["t"]["practicums"];
}) {
  return (
    <div className="flex h-48 flex-col items-center justify-center gap-4 rounded-2xl border border-dashed border-line text-muted">
      <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-wine/8">
        <Headphones size={28} strokeWidth={1.5} className="text-wine/60" />
      </div>
      <div className="text-center">
        <p className="text-sm font-semibold">{isEmpty ? p.noPracticums : "Bu filtr bo'yicha ma'lumot yo'q"}</p>
      </div>
      {!isAdmin && isEmpty && (
        <button
          onClick={onAdd}
          className="rounded-xl bg-wine px-4 py-2 text-xs font-bold text-white hover:bg-wine-dark"
        >
          Birinchi praktikumni yarating
        </button>
      )}
    </div>
  );
}

function PracticumCard({
  practicum,
  isAdmin,
  isExpanded,
  onToggle,
  onApprove,
  onReject,
  onEdit,
  onDelete,
  onAudioUploaded,
}: {
  practicum: Practicum;
  isAdmin: boolean;
  isExpanded: boolean;
  onToggle: () => void;
  onApprove: () => void;
  onReject: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onAudioUploaded: (updated: Practicum) => void;
}) {
  const { t } = useLang();
  const p = t.practicums;
  const audioRef = useRef<HTMLAudioElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [playing, setPlaying] = useState(false);

  const fullAudioUrl = mediaUrl(practicum.expert_audio_url);

  const handleAudioUpload = async (file: File) => {
    setUploading(true);
    try {
      const form = new FormData();
      form.append("file", file);
      const { data } = await api.post<Practicum>(
        `/practicums/${practicum.id}/audio`,
        form
      );
      onAudioUploaded(data);
    } catch {
      // ignore
    } finally {
      setUploading(false);
    }
  };

  const toggleAudio = () => {
    const el = audioRef.current;
    if (!el) return;
    if (el.paused) { el.play(); setPlaying(true); }
    else { el.pause(); setPlaying(false); }
  };

  return (
    <div className="overflow-hidden rounded-2xl border border-line bg-card transition-shadow hover:shadow-sm">
      {/* Header row */}
      <div className="flex items-center gap-4 p-4">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-wine/10">
          <Headphones size={20} className="text-wine" />
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span className="font-bold text-ink">{practicum.title}</span>
            <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${STATUS_COLOR[practicum.status]}`}>
              {p[practicum.status]}
            </span>
            <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${
              practicum.is_free
                ? "bg-green-100 text-green-700"
                : "bg-purple-100 text-purple-700"
            }`}>
              {practicum.is_free ? p.free : `${p.paid} · ${formatPrice(Number(practicum.price))}`}
            </span>
          </div>
          {practicum.category && (
            <div className="mt-1 text-xs text-muted">{practicum.category}</div>
          )}
          {practicum.expert_audio_url && (
            <div className="mt-1 flex items-center gap-1 text-[11px] text-green-600 font-semibold">
              <Mic size={11} />
              Audio yuklangan
            </div>
          )}
        </div>

        <div className="flex shrink-0 items-center gap-1.5">
          {isAdmin && practicum.status === "draft" && (
            <>
              <button
                onClick={onApprove}
                title="Tasdiqlash"
                className="flex items-center gap-1 rounded-lg bg-green-100 px-3 py-1.5 text-xs font-bold text-green-700 transition hover:bg-green-200"
              >
                <Check size={13} />
                Tasdiqlash
              </button>
              <button
                onClick={onReject}
                title="Rad etish"
                className="flex items-center gap-1 rounded-lg bg-red-100 px-3 py-1.5 text-xs font-bold text-red-700 transition hover:bg-red-200"
              >
                <X size={13} />
                Rad etish
              </button>
            </>
          )}

          {!isAdmin && (
            <>
              <button
                onClick={onEdit}
                title="Tahrirlash"
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-line text-muted transition hover:border-wine/30 hover:text-wine"
              >
                <Edit2 size={14} />
              </button>
              <button
                onClick={onDelete}
                title="O'chirish"
                className="flex h-8 w-8 items-center justify-center rounded-lg border border-line text-muted transition hover:border-red-300 hover:text-red-500"
              >
                <Trash2 size={14} />
              </button>
            </>
          )}

          <button
            onClick={onToggle}
            className="flex items-center gap-1 rounded-lg border border-line px-2.5 py-1.5 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine"
          >
            {isExpanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            Ko'rish
          </button>
        </div>
      </div>

      {/* Expanded detail */}
      {isExpanded && (
        <div className="border-t border-line bg-surface px-5 py-5 space-y-4">
          {practicum.description && (
            <p className="text-sm text-inkSoft leading-relaxed">{practicum.description}</p>
          )}

          {practicum.expert_text && (
            <div className="rounded-xl border border-line bg-card p-4">
              <p className="mb-2 text-xs font-bold uppercase tracking-wider text-muted">
                Ekspert matni
              </p>
              <p className="text-sm text-ink leading-relaxed whitespace-pre-wrap">
                {practicum.expert_text}
              </p>
            </div>
          )}

          {/* Audio section */}
          <div className="rounded-xl border border-line bg-card p-4">
            <p className="mb-3 text-xs font-bold uppercase tracking-wider text-muted">
              Ekspert ovozi
            </p>
            {fullAudioUrl ? (
              <div className="flex flex-wrap items-center gap-3">
                <button
                  onClick={toggleAudio}
                  className={`flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-bold transition ${
                    playing
                      ? "bg-wine text-white"
                      : "bg-wine/10 text-wine hover:bg-wine/20"
                  }`}
                >
                  <Play size={14} className={playing ? "fill-white" : "fill-wine"} />
                  {playing ? "To'xtatish" : "Tinglash"}
                </button>
                <audio
                  ref={audioRef}
                  src={fullAudioUrl}
                  preload="none"
                  onEnded={() => setPlaying(false)}
                />
                {!isAdmin && (
                  <button
                    onClick={() => fileRef.current?.click()}
                    disabled={uploading}
                    className="flex items-center gap-1.5 rounded-xl border border-line px-3 py-2 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine disabled:opacity-50"
                  >
                    <Upload size={13} />
                    {uploading ? "Yuklanmoqda…" : p.replaceAudio}
                  </button>
                )}
              </div>
            ) : (
              <div className="flex flex-wrap items-center gap-3">
                <span className="text-sm text-muted">{p.noAudio}</span>
                {!isAdmin && (
                  <button
                    onClick={() => fileRef.current?.click()}
                    disabled={uploading}
                    className="flex items-center gap-1.5 rounded-xl bg-wine px-3 py-2 text-xs font-bold text-white hover:bg-wine-dark disabled:opacity-50"
                  >
                    <Upload size={13} />
                    {uploading ? "Yuklanmoqda…" : p.uploadAudio}
                  </button>
                )}
              </div>
            )}

            {!isAdmin && (
              <input
                ref={fileRef}
                type="file"
                accept="audio/*"
                className="hidden"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) handleAudioUpload(file);
                  e.target.value = "";
                }}
              />
            )}
          </div>

          {/* Metadata */}
          <div className="flex flex-wrap gap-3 text-xs text-muted">
            <span>
              Yaratilgan: {new Date(practicum.created_at).toLocaleDateString("uz-UZ")}
            </span>
            {practicum.category && <span>Kategoriya: {practicum.category}</span>}
          </div>
        </div>
      )}
    </div>
  );
}

function CreatePracticumModal({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: () => void;
}) {
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const p = t.practicums;

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("");
  const [expertText, setExpertText] = useState("");
  const [isFree, setIsFree] = useState(true);
  const [price, setPrice] = useState("");
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const submit = async () => {
    if (!title.trim()) { setError("Sarlavha kiritilishi shart."); return; }
    const ok = await confirm({
      title: t.modal.createTitle("praktikum"),
      description: t.modal.createDesc("Praktikum"),
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (!ok) return;
    setSaving(true);
    try {
      const { data } = await api.post<Practicum>("/practicums", {
        title,
        description: description || null,
        category: category || null,
        expert_text: expertText || null,
        is_free: isFree,
        price: isFree ? 0 : Number(price) || 0,
      });

      if (audioFile) {
        const form = new FormData();
        form.append("file", audioFile);
        await api.post(`/practicums/${data.id}/audio`, form);
      }

      toast.success(p.createSuccess);
      onCreated();
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { detail?: string } } }).response?.data?.detail;
      setError(msg ?? "Xatolik yuz berdi.");
      setSaving(false);
    }
  };

  return (
    <ModalShell
      open
      title={p.addBtn}
      onClose={onClose}
      size="lg"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={submit}
          saving={saving}
          submitLabel="Yuborish"
        />
      }
    >
      <FormBody
        title={title} setTitle={setTitle}
        description={description} setDescription={setDescription}
        category={category} setCategory={setCategory}
        expertText={expertText} setExpertText={setExpertText}
        isFree={isFree} setIsFree={setIsFree}
        price={price} setPrice={setPrice}
        audioFile={audioFile} setAudioFile={setAudioFile}
        error={error}
        p={p}
      />
    </ModalShell>
  );
}

function EditPracticumModal({
  practicum,
  onClose,
  onSaved,
}: {
  practicum: Practicum;
  onClose: () => void;
  onSaved: (updated: Practicum) => void;
}) {
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const p = t.practicums;

  const [title, setTitle] = useState(practicum.title);
  const [description, setDescription] = useState(practicum.description ?? "");
  const [category, setCategory] = useState(practicum.category ?? "");
  const [expertText, setExpertText] = useState(practicum.expert_text ?? "");
  const [isFree, setIsFree] = useState(practicum.is_free);
  const [price, setPrice] = useState(String(practicum.price || ""));
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const submit = async () => {
    if (!title.trim()) { setError("Sarlavha kiritilishi shart."); return; }
    const ok = await confirm({
      title: t.modal.updateTitle("Praktikum"),
      description: t.modal.updateDesc("Praktikum"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (!ok) return;
    setSaving(true);
    try {
      const { data } = await api.patch<Practicum>(`/practicums/${practicum.id}`, {
        title,
        description: description || null,
        category: category || null,
        expert_text: expertText || null,
        is_free: isFree,
        price: isFree ? 0 : Number(price) || 0,
      });

      let final = data;
      if (audioFile) {
        const form = new FormData();
        form.append("file", audioFile);
        const { data: withAudio } = await api.post<Practicum>(
          `/practicums/${practicum.id}/audio`,
          form
        );
        final = withAudio;
      }

      toast.success(p.updateSuccess);
      onSaved(final);
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { detail?: string } } }).response?.data?.detail;
      setError(msg ?? "Xatolik yuz berdi.");
      setSaving(false);
    }
  };

  return (
    <ModalShell
      open
      title="Praktikumni tahrirlash"
      onClose={onClose}
      size="lg"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={submit}
          saving={saving}
          submitLabel="Saqlash"
        />
      }
    >
      <FormBody
        title={title} setTitle={setTitle}
        description={description} setDescription={setDescription}
        category={category} setCategory={setCategory}
        expertText={expertText} setExpertText={setExpertText}
        isFree={isFree} setIsFree={setIsFree}
        price={price} setPrice={setPrice}
        audioFile={audioFile} setAudioFile={setAudioFile}
        error={error}
        p={p}
      />
    </ModalShell>
  );
}

function ModalShell({
  open,
  title,
  onClose,
  children,
  footer,
  size = "md",
}: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  footer?: React.ReactNode;
  size?: "sm" | "md" | "lg" | "xl";
}) {
  return (
    <Modal open={open} onClose={onClose} title={title} size={size} footer={footer}>
      {children}
    </Modal>
  );
}

function FormBody({
  title, setTitle,
  description, setDescription,
  category, setCategory,
  expertText, setExpertText,
  isFree, setIsFree,
  price, setPrice,
  audioFile, setAudioFile,
  error,
  p,
}: {
  title: string; setTitle: (v: string) => void;
  description: string; setDescription: (v: string) => void;
  category: string; setCategory: (v: string) => void;
  expertText: string; setExpertText: (v: string) => void;
  isFree: boolean; setIsFree: (v: boolean) => void;
  price: string; setPrice: (v: string) => void;
  audioFile: File | null; setAudioFile: (f: File | null) => void;
  error: string;
  p: ReturnType<typeof useLang>["t"]["practicums"];
}) {
  const inputCls = "w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10";

  return (
    <div className="space-y-4 p-6">
      {error && (
        <div className="rounded-xl bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">
          {error}
        </div>
      )}

      <Field label={`${p.titleField} *`}>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Praktikum sarlavhasi"
          className={inputCls}
        />
      </Field>

      <div className="grid grid-cols-2 gap-3">
        <Field label={p.categoryField}>
          <input
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            placeholder="Nutq, Psixologiya…"
            className={inputCls}
          />
        </Field>
        <Field label={p.descField}>
          <input
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Qisqacha tavsif"
            className={inputCls}
          />
        </Field>
      </div>

      <Field label={p.textField}>
        <textarea
          value={expertText}
          onChange={(e) => setExpertText(e.target.value)}
          rows={5}
          placeholder="Ekspert tomonidan yozilgan matn..."
          className={`${inputCls} resize-none`}
        />
      </Field>

      {/* Free/Paid toggle */}
      <div>
        <label className="mb-1.5 block text-sm font-bold text-ink">Narx turi</label>
        <div className="flex gap-3">
          <button
            type="button"
            onClick={() => setIsFree(true)}
            className={`flex-1 rounded-xl border py-2.5 text-sm font-bold transition ${
              isFree
                ? "border-green-400 bg-green-50 text-green-700"
                : "border-line bg-surface text-muted hover:border-wine/30"
            }`}
          >
            {p.isFree}
          </button>
          <button
            type="button"
            onClick={() => setIsFree(false)}
            className={`flex-1 rounded-xl border py-2.5 text-sm font-bold transition ${
              !isFree
                ? "border-purple-400 bg-purple-50 text-purple-700"
                : "border-line bg-surface text-muted hover:border-wine/30"
            }`}
          >
            {p.isPaid}
          </button>
        </div>
        {!isFree && (
          <div className="mt-3">
            <label className="mb-1.5 block text-sm font-bold text-ink">{p.price}</label>
            <input
              type="number"
              min="0"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="0"
              className={inputCls}
            />
          </div>
        )}
      </div>

      {/* Audio upload */}
      <Field label={p.audioFile}>
        <label className="flex cursor-pointer items-center gap-3 rounded-xl border-2 border-dashed border-line bg-surface px-4 py-3 transition hover:border-wine/40">
          <Mic size={18} className="shrink-0 text-wine" />
          <span className="text-sm text-muted">
            {audioFile ? (
              <span className="font-semibold text-green-600">✓ {audioFile.name}</span>
            ) : (
              p.uploadAudio
            )}
          </span>
          <input
            type="file"
            accept="audio/*"
            className="hidden"
            onChange={(e) => setAudioFile(e.target.files?.[0] ?? null)}
          />
        </label>
      </Field>
    </div>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-bold text-ink">{label}</label>
      {children}
    </div>
  );
}
