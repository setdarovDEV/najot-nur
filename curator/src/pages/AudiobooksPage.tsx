import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Headphones,
  BookOpen,
  Music2,
  Trash2,
  ChevronDown,
  ChevronUp,
  Plus,
  Upload,
  CheckCircle2,
  Lock,
  Pencil,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import type { Audiobook, AudiobookDetail, AudiobookPage } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";
import { useConfirm } from "../lib/confirm";
import {
  Modal,
  ModalBody,
  ModalCancelButton,
  ModalFooter,
  ModalHeader,
  ModalSubmitButton,
} from "../components/Modal";

// ─── AudiobooksPage ────────────────────────────────────────────────────────────

export function AudiobooksPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const canEdit = true;
  const canPublish = true;
  const [showCreate, setShowCreate] = useState(false);
  const [editingBook, setEditingBook] = useState<Audiobook | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [publishingId, setPublishingId] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["audiobooks"],
    queryFn: async () =>
      (await api.get<Audiobook[]>("/admin/audiobooks")).data,
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/audiobooks/${id}`),
    onSuccess: () => {
      toast.success(t.audiobooks.deleteSuccess);
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const publishMutation = useMutation({
    mutationFn: (id: string) => api.post<{ message: string }>(`/admin/audiobooks/${id}/publish`),
    onMutate: (id) => setPublishingId(id),
    onSettled: () => setPublishingId(null),
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      toast.success(res.data?.message ?? "Audiokitob nashr qilindi.");
    },
    onError: (err) => {
      toast.error(apiError(err) || "Nashr qilishda xatolik yuz berdi.");
    },
  });

  const togglePages = (id: string) =>
    setExpandedId((prev) => (prev === id ? null : id));

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={t.audiobooks.title}
        subtitle={
          canEdit
            ? "Yuklash, sahifalarni tahrirlash va nashr qilish"
            : "Faqat ko'rish rejimi — kontent kurator tomonidan boshqariladi"
        }
        actions={
          canEdit ? (
            <button
              onClick={() => setShowCreate(true)}
              className="flex items-center gap-2 rounded-xl bg-wine px-5 py-2.5 text-sm font-bold text-white hover:bg-wine-dark"
            >
              <Plus size={16} />
              Yangi audiokitob
            </button>
          ) : (
            <span className="flex items-center gap-2 rounded-xl border border-line bg-card px-4 py-2 text-xs font-semibold text-muted">
              <Lock size={14} />
              Faqat ko'rish
            </span>
          )
        }
      />

      {showCreate && canEdit && (
        <AudiobookModal onDone={() => setShowCreate(false)} />
      )}
      {editingBook && canEdit && (
        <AudiobookModal
          initial={editingBook}
          onDone={() => setEditingBook(null)}
        />
      )}

      {isLoading && <p className="text-muted">Yuklanmoqda…</p>}

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
        {data?.map((b) => (
          <div key={b.id}>
            {/* Card */}
            <div className="rounded-2xl border border-line bg-card p-5">
              {/* Cover */}
              {b.cover_url ? (
                <img
                  src={mediaUrl(b.cover_url)!}
                  alt={b.title}
                  className="mb-3 h-28 w-full rounded-xl object-cover"
                />
              ) : (
                <div className="mb-3 flex h-28 items-center justify-center rounded-xl bg-gradient-to-br from-wine to-wine-deep">
                  <Headphones size={36} className="text-white/80" />
                </div>
              )}

              <h3 className="font-bold text-ink">{b.title}</h3>
              <p className="text-sm text-muted">{b.author ?? "Muallif yo'q"}</p>

              <div className="mt-3 flex items-center justify-between">
                <span className="text-xs text-muted">{b.total_pages} sahifa</span>
                <span
                  className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                    b.is_free
                      ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                      : "bg-wine-100 text-wine dark:bg-wine-200/20 dark:text-wine-300"
                  }`}
                >
                  {b.is_free ? "Bepul" : "Sotuvda"}
                </span>
              </div>

              {/* Action buttons */}
              <div className="mt-4 flex flex-col gap-2">
                {canEdit && (
                  <AudioUploadRow
                    bookId={b.id}
                    audioUrl={b.audio_url ?? null}
                    onUploaded={() => qc.invalidateQueries({ queryKey: ["audiobooks"] })}
                  />
                )}

                {canEdit && (
                  <button
                    onClick={() => togglePages(b.id)}
                    className="flex w-full items-center justify-center gap-2 rounded-lg border border-line py-2 text-sm font-semibold text-ink hover:bg-surface"
                  >
                    <BookOpen size={15} />
                    Sahifalarni boshqarish
                    {expandedId === b.id ? (
                      <ChevronUp size={14} />
                    ) : (
                      <ChevronDown size={14} />
                    )}
                  </button>
                )}

                {canEdit && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => setEditingBook(b)}
                      className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-line py-2 text-sm font-semibold text-ink transition hover:bg-surface"
                    >
                      <Pencil size={14} />
                      Tahrirlash
                    </button>

                    {canPublish ? (
                      b.is_published ? (
                        <div className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-green-200 bg-green-50 py-2 text-sm font-semibold text-green-700">
                          <CheckCircle2 size={14} />
                          Nashr qilingan
                        </div>
                      ) : (
                        <button
                          onClick={async () => {
                            const ok = await confirm({
                              title: t.audiobooks.confirmPublish(b.title),
                              variant: "primary",
                              confirmText: t.modal.publish,
                            });
                            if (ok) publishMutation.mutate(b.id);
                          }}
                          disabled={publishMutation.isPending}
                          className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-wine py-2 text-sm font-semibold text-wine transition hover:bg-wine hover:text-white disabled:opacity-60"
                        >
                          {publishingId === b.id && publishMutation.isPending ? (
                            <>
                              <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-wine border-t-transparent" />
                              Nashr qilinmoqda…
                            </>
                          ) : (
                            <>
                              <CheckCircle2 size={14} />
                              Nashr qilish
                            </>
                          )}
                        </button>
                      )
                    ) : (
                      <div className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-line bg-surface py-2 text-xs font-semibold text-muted">
                        <Lock size={12} />
                        Nashr faqat admin uchun
                      </div>
                    )}
                    {canPublish && (
                      <button
                        onClick={async () => {
                          const ok = await confirm({
                            title: t.audiobooks.confirmDelete(b.title),
                            description: t.modal.deleteDesc(
                              "audiokitob",
                              b.title,
                            ),
                            variant: "danger",
                            confirmText: t.modal.delete,
                          });
                          if (ok) deleteMutation.mutate(b.id);
                        }}
                        disabled={deleteMutation.isPending}
                        className="rounded-lg border border-red-200 px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60"
                      >
                        <Trash2 size={14} />
                      </button>
                    )}
                  </div>
                )}
              </div>

              {deleteMutation.isError && (
                <p className="mt-2 text-xs text-red-600">
                  {apiError(deleteMutation.error)}
                </p>
              )}
            </div>

            {/* Inline pages panel */}
            {canEdit && expandedId === b.id && <PagesPanel audiobookId={b.id} />}
          </div>
        ))}
      </div>

      {data && data.length === 0 && !isLoading && (
        <p className="rounded-xl border border-line bg-card p-6 text-muted">
          Hozircha audiokitoblar yo'q. Yuqoridagi tugma orqali qo'shing.
        </p>
      )}
    </div>
  );
}

// ─── Create / Edit Modal ───────────────────────────────────────────────────────

function AudiobookModal({
  initial,
  onDone,
}: {
  initial?: Audiobook;
  onDone: () => void;
}) {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const isEdit = !!initial;

  const [title, setTitle] = useState(initial?.title ?? "");
  const [author, setAuthor] = useState(initial?.author ?? "");
  const [description, setDescription] = useState(initial?.description ?? "");
  const [isFree, setIsFree] = useState(initial?.is_free ?? true);
  const [price, setPrice] = useState(initial?.price ? String(initial.price) : "");
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const coverRef = useRef<HTMLInputElement>(null);
  const audioRef = useRef<HTMLInputElement>(null);

  const save = useMutation({
    mutationFn: async () => {
      if (isEdit) {
        await api.patch(`/admin/audiobooks/${initial.id}`, {
          title,
          author: author || null,
          description: description || null,
          is_free: isFree,
          price: isFree ? 0 : parseFloat(price || "0"),
        });
        if (coverFile) {
          const fd = new FormData();
          fd.append("file", coverFile);
          await api.post(`/admin/audiobooks/${initial.id}/cover`, fd, {
            headers: { "Content-Type": "multipart/form-data" },
          });
        }
        return initial;
      }

      const res = await api.post<Audiobook>("/admin/audiobooks", {
        title,
        author: author || null,
        description: description || null,
        is_free: isFree,
        price: isFree ? undefined : price,
      });
      const book = res.data;

      if (coverFile) {
        const fd = new FormData();
        fd.append("file", coverFile);
        await api.post(`/admin/audiobooks/${book.id}/cover`, fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      if (audioFile) {
        const fd = new FormData();
        fd.append("file", audioFile);
        await api.post(`/admin/audiobooks/${book.id}/audio`, fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      return book;
    },
    onSuccess: () => {
      toast.success(isEdit ? t.audiobooks.updateSuccess : t.audiobooks.createSuccess);
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      onDone();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleSave() {
    const ok = await confirm({
      title: isEdit
        ? t.modal.updateTitle("audiokitob")
        : t.modal.createTitle("audiokitob"),
      description: isEdit
        ? t.modal.updateDesc("Audiokitob")
        : t.modal.createDesc("Audiokitob"),
      variant: "primary",
      confirmText: isEdit ? t.modal.save : t.modal.create,
    });
    if (ok) save.mutate();
  }

  return (
    <Modal open onClose={onDone} size="lg">
      <ModalHeader
        title={isEdit ? "Audiokitobni tahrirlash" : "Yangi audiokitob qo'shish"}
        onClose={onDone}
      />
      <ModalBody>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              {t.audiobooks.titleField}
            </label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Kitob nomi"
              className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>

          <div className="sm:col-span-2">
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              {t.audiobooks.author}
            </label>
            <input
              value={author}
              onChange={(e) => setAuthor(e.target.value)}
              placeholder="Muallif"
              className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>

          <div className="sm:col-span-2">
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              {t.audiobooks.description}
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Tavsif (ixtiyoriy)"
              rows={3}
              className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>

          <div>
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              {t.audiobooks.free} / {t.audiobooks.premium}
            </label>
            <label className="flex items-center gap-2 rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink">
              <input
                type="checkbox"
                checked={isFree}
                onChange={(e) => setIsFree(e.target.checked)}
                className="accent-wine"
              />
              Bepul kitob
            </label>
          </div>

          {!isFree && (
            <div>
              <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
                Narx (so'm)
              </label>
              <input
                type="number"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="Narxi (so'm)"
                className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
              />
            </div>
          )}

          {/* Cover upload */}
          <div className="sm:col-span-2">
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              {t.audiobooks.coverImage}
            </label>
            <button
              type="button"
              onClick={() => coverRef.current?.click()}
              className="flex w-full items-center gap-2 rounded-xl border border-line bg-card px-4 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
            >
              <Upload size={14} />
              {coverFile ? coverFile.name : "Muqova rasmini yuklash"}
            </button>
            <input
              ref={coverRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => setCoverFile(e.target.files?.[0] ?? null)}
            />
          </div>

          {/* Main audio upload (create only) */}
          {!isEdit && (
            <div className="sm:col-span-2">
              <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
                {t.audiobooks.audioFile}
              </label>
              <button
                type="button"
                onClick={() => audioRef.current?.click()}
                className={`flex w-full items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-semibold transition ${
                  audioFile
                    ? "border-green-500/40 bg-green-500/10 text-green-700 dark:text-green-400"
                    : "border-dashed border-wine/60 bg-wine text-white hover:bg-wine-dark"
                }`}
              >
                <Music2 size={14} />
                {audioFile ? audioFile.name : "Asosiy audio yuklash (mp3 / m4a)"}
              </button>
              <input
                ref={audioRef}
                type="file"
                accept="audio/*"
                className="hidden"
                onChange={(e) => setAudioFile(e.target.files?.[0] ?? null)}
              />
            </div>
          )}
        </div>
      </ModalBody>
      <ModalFooter>
        <ModalCancelButton onClick={onDone}>{t.common.cancel}</ModalCancelButton>
        <ModalSubmitButton
          onClick={handleSave}
          loading={save.isPending}
          disabled={!title}
        >
          {isEdit ? t.common.save : t.modal.create}
        </ModalSubmitButton>
      </ModalFooter>
    </Modal>
  );
}

// ─── PagesPanel ───────────────────────────────────────────────────────────────

function PagesPanel({ audiobookId }: { audiobookId: string }) {
  const [editingPage, setEditingPage] = useState<AudiobookPage | "new" | null>(
    null
  );

  const { data: book, isLoading } = useQuery({
    queryKey: ["audiobook", audiobookId],
    queryFn: async () =>
      (await api.get<AudiobookDetail>(`/admin/audiobooks/${audiobookId}`)).data,
  });

  const nextPageNumber = book ? (book.pages.length > 0 ? Math.max(...book.pages.map((p) => p.page_number)) + 1 : 1) : 1;

  return (
    <div className="mt-1 rounded-2xl border border-line bg-card p-5">
      <div className="mb-4 flex items-center justify-between">
        <h4 className="font-bold text-ink">Sahifalar</h4>
        <button
          onClick={() => setEditingPage("new")}
          className="flex items-center gap-1.5 rounded-lg bg-wine px-3 py-1.5 text-xs font-bold text-white hover:bg-wine-dark"
        >
          <Plus size={13} />
          Sahifa qo'shish
        </button>
      </div>

      {isLoading && <p className="text-sm text-muted">Yuklanmoqda…</p>}

      {/* Page list */}
      {book && (
        <div className="flex flex-col gap-1">
          {book.pages.length === 0 && editingPage === null && (
            <p className="text-sm text-muted">Hali sahifalar yo'q.</p>
          )}
          {book.pages.map((page) => (
            <button
              key={page.id}
              onClick={() => setEditingPage(page)}
              className="flex items-center gap-3 rounded-xl border border-line bg-card px-4 py-3 text-left text-sm text-ink transition hover:border-wine/40"
            >
              <span className="w-8 shrink-0 rounded-lg bg-wine-100 py-0.5 text-center text-xs font-bold text-muted dark:bg-wine-200/20 dark:text-wine-300">
                {page.page_number}
              </span>
              <span className="flex-1 truncate text-muted">
                {page.content
                  ? page.content.slice(0, 50) + (page.content.length > 50 ? "…" : "")
                  : "Matn yo'q"}
              </span>
              {page.audio_url && (
                <Music2 size={14} className="shrink-0 text-wine" />
              )}
            </button>
          ))}
        </div>
      )}

      {/* Page editor modal */}
      {editingPage !== null && book && (
        <PageEditorModal
          audiobookId={audiobookId}
          page={editingPage === "new" ? null : editingPage}
          defaultPageNumber={editingPage === "new" ? nextPageNumber : undefined}
          onDone={() => setEditingPage(null)}
        />
      )}
    </div>
  );
}

// ─── Page Editor Modal ─────────────────────────────────────────────────────────

function PageEditorModal({
  audiobookId,
  page,
  defaultPageNumber,
  onDone,
}: {
  audiobookId: string;
  page: AudiobookPage | null;
  defaultPageNumber?: number;
  onDone: () => void;
}) {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const [pageNumber, setPageNumber] = useState(
    page ? page.page_number : (defaultPageNumber ?? 1)
  );
  const [content, setContent] = useState(page?.content ?? "");

  const saveText = useMutation({
    mutationFn: () =>
      api.put(`/admin/audiobooks/${audiobookId}/pages`, {
        page_number: pageNumber,
        content,
      }),
    onSuccess: () => {
      toast.success(t.audiobooks.pageSaveSuccess);
      qc.invalidateQueries({ queryKey: ["audiobook", audiobookId] });
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      onDone();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const deletePage = useMutation({
    mutationFn: () =>
      api.delete(`/admin/audiobooks/${audiobookId}/pages/${pageNumber}`),
    onSuccess: () => {
      toast.success(t.audiobooks.pageDeleteSuccess);
      qc.invalidateQueries({ queryKey: ["audiobook", audiobookId] });
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      onDone();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleSave() {
    const ok = await confirm({
      title: page
        ? t.modal.updateTitle("sahifa")
        : t.modal.createTitle("sahifa"),
      description: page
        ? t.modal.updateDesc("Sahifa")
        : t.modal.createDesc("Sahifa"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (ok) saveText.mutate();
  }

  async function handleDelete() {
    const ok = await confirm({
      title: t.audiobooks.confirmDeletePage(pageNumber),
      description: t.modal.deleteDesc("sahifa", String(pageNumber)),
      variant: "danger",
      confirmText: t.modal.delete,
    });
    if (ok) deletePage.mutate();
  }

  return (
    <Modal open onClose={onDone} size="md">
      <ModalHeader
        title={page ? `Sahifa ${page.page_number} tahrirlash` : "Yangi sahifa"}
        onClose={onDone}
      />
      <ModalBody>
        <div className="space-y-4">
          {/* Page number */}
          <div>
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              Sahifa raqami
            </label>
            <input
              type="number"
              value={pageNumber}
              onChange={(e) => setPageNumber(Number(e.target.value))}
              className="w-24 rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>

          {/* Content */}
          <div>
            <label className="mb-1 block text-xs font-bold text-muted uppercase tracking-wide">
              Matn
            </label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={6}
              placeholder="Sahifa matni…"
              className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>
        </div>
      </ModalBody>
      <ModalFooter>
        {page ? (
          <button
            onClick={handleDelete}
            disabled={deletePage.isPending}
            className="mr-auto flex items-center gap-1.5 rounded-xl border border-red-200 px-4 py-2.5 text-sm font-semibold text-red-600 transition hover:bg-red-50 disabled:opacity-60"
          >
            <Trash2 size={14} />
            O'chirish
          </button>
        ) : null}
        <ModalCancelButton onClick={onDone}>{t.common.cancel}</ModalCancelButton>
        <ModalSubmitButton
          onClick={handleSave}
          loading={saveText.isPending}
        >
          {t.common.save}
        </ModalSubmitButton>
      </ModalFooter>
    </Modal>
  );
}

// ─── Audio upload row per audiobook card ────────────────────────────────────

function AudioUploadRow({
  bookId,
  audioUrl,
  onUploaded,
}: {
  bookId: string;
  audioUrl: string | null;
  onUploaded: () => void;
}) {
  const [uploading, setUploading] = useState(false);

  async function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      await api.post(`/admin/audiobooks/${bookId}/audio`, fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      onUploaded();
    } finally {
      setUploading(false);
      e.target.value = "";
    }
  }

  return (
    <label
      className={`flex cursor-pointer items-center justify-between rounded-lg border px-3 py-2 text-sm transition ${
        audioUrl
          ? "border-green-500/40 bg-green-500/10 text-green-700 dark:text-green-400"
          : "border-wine bg-wine text-white hover:bg-wine-dark"
      }`}
    >
      <span className="flex items-center gap-2 font-semibold">
        <Music2 size={14} />
        {audioUrl
          ? "Asosiy audio yuklangan"
          : uploading
          ? "Yuklanmoqda..."
          : "Asosiy audio yuklash"}
      </span>
      {!uploading && (
        <span className="text-xs opacity-60">
          {audioUrl ? "Almashtirish" : "mp3 / m4a"}
        </span>
      )}
      <input
        type="file"
        accept="audio/*"
        className="hidden"
        disabled={uploading}
        onChange={handleChange}
      />
    </label>
  );
}
