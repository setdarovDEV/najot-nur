import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Trash2,
  Upload,
  Mic,
  Play,
  Pencil,
  CheckCircle2,
  Volume2,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";
import { useConfirm } from "../lib/confirm";
import { Modal, ModalFooter } from "../components/Modal";
import { Reveal, PrimaryButton, GlassInput, GlassTextarea, GlassSelect, StatusPill } from "../components/glass";

interface Reference {
  id: string;
  title: string;
  text: string;
  reference_audio_url: string | null;
  language: string;
  difficulty: string;
  created_at: string;
}

// ─── ReferencesPage ────────────────────────────────────────────────────────────

export function ReferencesPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const r = t.references;
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<Reference | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["references"],
    queryFn: async () => (await api.get<Reference[]>("/admin/references")).data,
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/references/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["references"] });
      toast.success(t.references.deleteSuccess);
    },
    onError: (err) => toast.error(apiError(err)),
  });

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={r.title}
        subtitle={r.subtitle}
        actions={
          <PrimaryButton onClick={() => { setShowCreate(true); setEditing(null); }}>
            <Plus size={16} />
            {r.addBtn}
          </PrimaryButton>
        }
      />

      <ReferenceForm
        open={showCreate}
        onClose={() => setShowCreate(false)}
      />
      <ReferenceForm
        open={!!editing}
        initial={editing ?? undefined}
        onClose={() => setEditing(null)}
      />

      {isLoading && <p className="text-muted">{t.common.loading}</p>}

      <div className="flex flex-col gap-4">
        {data?.length === 0 && (
          <p className="rounded-2xl border border-line bg-card p-8 text-center text-muted">
            {r.noRefs}
          </p>
        )}
        {data?.map((ref, i) => (
          <Reveal key={ref.id} index={i}>
            <ReferenceCard
              ref_={ref}
              onEdit={() => { setEditing(ref); setShowCreate(false); }}
              onDelete={async () => {
                const ok = await confirm({
                  title: r.deleteConfirm(ref.title),
                  description: t.modal.deleteDesc("matn", ref.title),
                  variant: "danger",
                  confirmText: t.modal.delete,
                });
                if (ok) deleteMutation.mutate(ref.id);
              }}
            />
          </Reveal>
        ))}
      </div>
    </div>
  );
}

// ─── Card ─────────────────────────────────────────────────────────────────────

function ReferenceCard({
  ref_,
  onEdit,
  onDelete,
}: {
  ref_: Reference;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const { t } = useLang();
  const r = t.references;
  const qc = useQueryClient();
  const toast = useToast();
  const audioRef = useRef<HTMLAudioElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const diffLabel: Record<string, string> = {
    easy: r.easy,
    medium: r.medium,
    hard: r.hard,
  };

  const audioMutation = useMutation({
    mutationFn: async (file: File) => {
      const form = new FormData();
      form.append("file", file);
      return api.post(`/admin/references/${ref_.id}/audio`, form);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["references"] });
      toast.success("Audio yuklandi.");
    },
    onError: (err) => toast.error(apiError(err)),
  });

  const fullAudioUrl = mediaUrl(ref_.reference_audio_url);

  return (
    <div className="rounded-2xl border border-line bg-card p-6">
      <div className="flex flex-wrap items-start gap-4">
        {/* Icon */}
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-wine/10 dark:bg-wine/15">
          <Mic size={22} className="text-wine dark:text-wine-300" />
        </div>

        {/* Main info */}
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-base font-extrabold text-ink">{ref_.title}</h3>
            <StatusPill tone="neutral" className="uppercase">
              {diffLabel[ref_.difficulty] ?? ref_.difficulty}
            </StatusPill>
            <StatusPill tone="neutral" className="uppercase">
              {ref_.language.toUpperCase()}
            </StatusPill>
          </div>
          <p className="mt-2 line-clamp-3 text-sm text-inkSoft leading-relaxed">
            {ref_.text}
          </p>
        </div>

        {/* Actions */}
        <div className="flex shrink-0 items-center gap-2">
          <button
            onClick={onEdit}
            className="press flex items-center gap-1.5 rounded-full border border-line px-3 py-2 text-xs font-semibold text-ink hover:border-wine/30 hover:text-wine dark:hover:text-wine-300"
          >
            <Pencil size={14} />
            {t.common.edit}
          </button>
          <button
            onClick={onDelete}
            className="press flex items-center gap-1.5 rounded-full border border-line px-3 py-2 text-xs font-semibold text-red-500 hover:border-red-200 hover:bg-red-50 dark:hover:border-red-800 dark:hover:bg-red-900/20"
          >
            <Trash2 size={14} />
            {t.common.delete}
          </button>
        </div>
      </div>

      {/* Audio section */}
      <div className="mt-4 flex flex-wrap items-center gap-3 border-t border-line pt-4">
        {fullAudioUrl ? (
          <>
            <span className="flex items-center gap-1.5 text-xs font-semibold text-green-600 dark:text-green-400">
              <CheckCircle2 size={14} />
              {r.hasAudio}
            </span>
            <button
              onClick={() => {
                if (audioRef.current) {
                  if (audioRef.current.paused) audioRef.current.play();
                  else audioRef.current.pause();
                }
              }}
              className="press flex items-center gap-1.5 rounded-full bg-wine/10 px-3 py-1.5 text-xs font-semibold text-wine hover:bg-wine/20 dark:bg-wine/15 dark:text-wine-300 dark:hover:bg-wine/25"
            >
              <Play size={13} />
              Tinglash
            </button>
            <audio ref={audioRef} src={fullAudioUrl} preload="none" />
            <button
              onClick={() => fileRef.current?.click()}
              disabled={audioMutation.isPending}
              className="press flex items-center gap-1.5 rounded-full border border-line px-3 py-1.5 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine"
            >
              <Upload size={13} />
              {audioMutation.isPending ? "Yuklanmoqda…" : r.replaceAudio}
            </button>
          </>
        ) : (
          <>
            <span className="flex items-center gap-1.5 text-xs font-semibold text-muted">
              <Volume2 size={14} />
              {r.noAudio}
            </span>
            <button
              onClick={() => fileRef.current?.click()}
              disabled={audioMutation.isPending}
              className="press flex items-center gap-1.5 rounded-full bg-wine px-3 py-1.5 text-xs font-bold text-white hover:bg-wine-dark"
            >
              <Upload size={13} />
              {audioMutation.isPending ? "Yuklanmoqda…" : r.uploadAudio}
            </button>
          </>
        )}
        <input
          ref={fileRef}
          type="file"
          accept="audio/*"
          className="hidden"
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) audioMutation.mutate(file);
            e.target.value = "";
          }}
        />
      </div>
    </div>
  );
}

// ─── Create / Edit Form (Modal) ──────────────────────────────────────────────

function ReferenceForm({
  open,
  initial,
  onClose,
}: {
  open: boolean;
  initial?: Reference;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const { t } = useLang();
  const r = t.references;
  const toast = useToast();
  const confirm = useConfirm();

  const isEdit = !!initial;
  const [title, setTitle] = useState(initial?.title ?? "");
  const [text, setText] = useState(initial?.text ?? "");
  const [difficulty, setDifficulty] = useState(initial?.difficulty ?? "easy");
  const [language, setLanguage] = useState(initial?.language ?? "uz");
  const [audioFile, setAudioFile] = useState<File | null>(null);

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (isEdit) {
        await api.patch(`/admin/references/${initial.id}`, {
          title,
          text,
          difficulty,
          language,
        });
        if (audioFile) {
          const form = new FormData();
          form.append("file", audioFile);
          await api.post(`/admin/references/${initial.id}/audio`, form);
        }
      } else {
        const form = new FormData();
        form.append("title", title);
        form.append("text", text);
        form.append("difficulty", difficulty);
        form.append("language", language);
        if (audioFile) form.append("audio", audioFile);
        await api.post("/admin/references", form);
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["references"] });
      toast.success(
        isEdit ? t.references.updateSuccess : t.references.createSuccess,
      );
      onClose();
    },
    onError: (err) => toast.error(apiError(err)),
  });

  async function handleSave() {
    if (!title.trim() || !text.trim()) return;
    const ok = await confirm({
      title: isEdit
        ? t.modal.updateTitle("matn")
        : t.modal.createTitle("matn"),
      description: isEdit
        ? t.modal.updateDesc("Matn")
        : t.modal.createDesc("Matn"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (ok) saveMutation.mutate();
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEdit ? "Matnni tahrirlash" : r.addBtn}
      subtitle={isEdit ? undefined : "Yangi talaffuz matni qo'shing"}
      size="lg"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={handleSave}
          saving={saveMutation.isPending}
          submitDisabled={!title.trim() || !text.trim()}
          submitLabel={
            saveMutation.isPending ? t.common.saving : t.common.save
          }
        />
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            {r.titleField} *
          </label>
          <GlassInput
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Masalan: Kirish so'zi"
          />
        </div>

        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            {r.textField} *
          </label>
          <GlassTextarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={5}
            placeholder="Foydalanuvchilar o'qishi kerak bo'lgan matn..."
          />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            {r.difficulty}
          </label>
          <GlassSelect
            value={difficulty}
            onChange={(e) => setDifficulty(e.target.value)}
          >
            <option value="easy">{r.easy}</option>
            <option value="medium">{r.medium}</option>
            <option value="hard">{r.hard}</option>
          </GlassSelect>
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            {r.language}
          </label>
          <GlassSelect
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
          >
            <option value="uz">O'zbek</option>
            <option value="ru">Русский</option>
            <option value="en">English</option>
          </GlassSelect>
        </div>

        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-xs font-bold text-muted uppercase tracking-wide">
            {r.audioFile}
          </label>
          <label className="flex cursor-pointer items-center gap-3 rounded-xl border-2 border-dashed border-line bg-card px-4 py-3 transition hover:border-wine/40">
            <Mic size={18} className="shrink-0 text-wine" />
            <span className="text-sm text-muted">
              {audioFile ? (
                <span className="font-semibold text-green-600 dark:text-green-400">
                  ✓ {audioFile.name}
                </span>
              ) : (
                r.uploadAudio
              )}
            </span>
            <input
              type="file"
              accept="audio/*"
              className="hidden"
              onChange={(e) => setAudioFile(e.target.files?.[0] ?? null)}
            />
          </label>
        </div>
      </div>
    </Modal>
  );
}
