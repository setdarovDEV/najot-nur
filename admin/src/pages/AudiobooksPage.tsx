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
  Save,
  Upload,
  CheckCircle2,
  Lock,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import type { Audiobook, AudiobookDetail, AudiobookPage } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useAuth } from "../lib/auth";
import { useToast } from "../lib/toast";

// ─── AudiobooksPage ────────────────────────────────────────────────────────────

export function AudiobooksPage() {
  const qc = useQueryClient();
  const { perms } = useAuth();
  const { t } = useLang();
  const toast = useToast();
  const canEdit = perms.canUpload;
  const canPublish = perms.canPublish;
  const [showCreate, setShowCreate] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [publishingId, setPublishingId] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["audiobooks"],
    queryFn: async () =>
      (await api.get<Audiobook[]>("/admin/audiobooks")).data,
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/audiobooks/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["audiobooks"] }),
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
    <div className="p-8">
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
              onClick={() => setShowCreate((v) => !v)}
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

      {showCreate && canEdit && <CreateForm onDone={() => setShowCreate(false)} />}

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
                      ? "bg-green-100 text-green-700"
                      : "bg-wine-100 text-wine"
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
                    {canPublish ? (
                      b.is_published ? (
                        <div className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-green-200 bg-green-50 py-2 text-sm font-semibold text-green-700">
                          <CheckCircle2 size={14} />
                          Nashr qilingan
                        </div>
                      ) : (
                        <button
                          onClick={() => publishMutation.mutate(b.id)}
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
                        onClick={() => {
                          if (confirm("Audiokitobni o'chirishni tasdiqlaysizmi?")) {
                            deleteMutation.mutate(b.id);
                          }
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

// ─── CreateForm ────────────────────────────────────────────────────────────────

function CreateForm({ onDone }: { onDone: () => void }) {
  const qc = useQueryClient();
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [description, setDescription] = useState("");
  const [isFree, setIsFree] = useState(true);
  const [price, setPrice] = useState("");
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const coverRef = useRef<HTMLInputElement>(null);
  const audioRef = useRef<HTMLInputElement>(null);

  const create = useMutation({
    mutationFn: async () => {
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
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      onDone();
    },
  });

  return (
    <div className="mb-6 rounded-2xl border border-line bg-card p-5">
      <h2 className="mb-4 font-bold text-ink">Yangi audiokitob qo'shish</h2>
      <div className="grid gap-3 sm:grid-cols-2">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Kitob nomi"
          className="rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine"
        />
        <input
          value={author}
          onChange={(e) => setAuthor(e.target.value)}
          placeholder="Muallif"
          className="rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine"
        />
      </div>

      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="Tavsif (ixtiyoriy)"
        rows={3}
        className="mt-3 w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine"
      />

      <label className="mt-3 flex items-center gap-2 text-sm text-ink">
        <input
          type="checkbox"
          checked={isFree}
          onChange={(e) => setIsFree(e.target.checked)}
          className="accent-wine"
        />
        Bepul kitob
      </label>

      {!isFree && (
        <input
          type="number"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
          placeholder="Narxi (so'm)"
          className="mt-3 w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine sm:w-1/2"
        />
      )}

      {/* Cover upload */}
      <div className="mt-3">
        <button
          type="button"
          onClick={() => coverRef.current?.click()}
          className="flex items-center gap-2 rounded-lg border border-line px-4 py-2 text-sm font-semibold text-ink hover:bg-surface"
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

      {/* Main audio upload */}
      <div className="mt-3">
        <button
          type="button"
          onClick={() => audioRef.current?.click()}
          className={`flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-semibold transition ${
            audioFile
              ? "border-green-500/40 bg-green-500/10 text-green-700 dark:text-green-400"
              : "border-dashed border-wine/60 bg-wine dark:text-white text-white hover:bg-wine-dark"
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

      <div className="mt-4 flex gap-2">
        <button
          disabled={!title || create.isPending}
          onClick={() => create.mutate()}
          className="rounded-lg bg-wine px-5 py-2 text-sm font-bold text-white disabled:opacity-60"
        >
          {create.isPending ? "Saqlanmoqda…" : "Saqlash"}
        </button>
        <button
          onClick={onDone}
          className="rounded-lg border border-line px-5 py-2 text-sm font-semibold text-ink"
        >
          Bekor qilish
        </button>
      </div>
      {create.isError && (
        <p className="mt-2 text-sm text-red-600">{apiError(create.error)}</p>
      )}
    </div>
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
          {book.pages.length === 0 && !editingPage && (
            <p className="text-sm text-muted">Hali sahifalar yo'q.</p>
          )}
          {book.pages.map((page) => (
            <button
              key={page.id}
              onClick={() =>
                setEditingPage((prev) =>
                  prev !== "new" && prev?.id === page.id ? null : page
                )
              }
              className={`flex items-center gap-3 rounded-xl border px-4 py-3 text-left text-sm transition ${
                editingPage !== "new" &&
                (editingPage as AudiobookPage)?.id === page.id
                  ? "border-wine bg-card text-wine"
                  : "border-line bg-card text-ink hover:border-wine/40"
              }`}
            >
              <span className="w-8 shrink-0 rounded-lg bg-wine-100 py-0.5 text-center text-xs font-bold text-muted">
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

      {/* Page editor */}
      {editingPage !== null && book && (
        <PageEditor
          audiobookId={audiobookId}
          page={editingPage === "new" ? null : editingPage}
          defaultPageNumber={editingPage === "new" ? nextPageNumber : undefined}
          onDone={() => setEditingPage(null)}
        />
      )}
    </div>
  );
}

// ─── PageEditor ───────────────────────────────────────────────────────────────

function PageEditor({
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
      qc.invalidateQueries({ queryKey: ["audiobook", audiobookId] });
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
    },
  });

  const deletePage = useMutation({
    mutationFn: () =>
      api.delete(`/admin/audiobooks/${audiobookId}/pages/${pageNumber}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["audiobook", audiobookId] });
      qc.invalidateQueries({ queryKey: ["audiobooks"] });
      onDone();
    },
  });

  return (
    <div className="mt-4 rounded-xl border border-line bg-card p-4">
      <div className="mb-3 flex items-center justify-between">
        <h5 className="font-semibold text-ink">
          {page ? `Sahifa ${page.page_number} tahrirlash` : "Yangi sahifa"}
        </h5>
        {page && (
          <button
            onClick={() => {
              if (confirm("Bu sahifani o'chirishni tasdiqlaysizmi?")) {
                deletePage.mutate();
              }
            }}
            disabled={deletePage.isPending}
            className="flex items-center gap-1.5 rounded-lg border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60"
          >
            <Trash2 size={12} />
            Sahifani o'chirish
          </button>
        )}
      </div>

      {/* Page number */}
      <div className="mb-3">
        <label className="mb-1 block text-xs font-semibold text-muted">
          Sahifa raqami
        </label>
        <input
          type="number"
          value={pageNumber}
          onChange={(e) => setPageNumber(Number(e.target.value))}
          className="w-24 rounded-lg border border-line bg-card px-3 py-1.5 text-sm text-ink outline-none focus:border-wine"
        />
      </div>

      {/* Content */}
      <div className="mb-3">
        <label className="mb-1 block text-xs font-semibold text-muted">
          Matn
        </label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          rows={6}
          placeholder="Sahifa matni…"
          className="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine"
        />
      </div>

      {/* Save text */}
      <button
        onClick={() => saveText.mutate()}
        disabled={saveText.isPending}
        className="mb-4 flex items-center gap-2 rounded-lg bg-wine px-4 py-2 text-sm font-bold text-white disabled:opacity-60"
      >
        <Save size={14} />
        {saveText.isPending ? "Saqlanmoqda…" : "Matnni saqlash"}
      </button>
      {saveText.isError && (
        <p className="mb-2 text-xs text-red-600">{apiError(saveText.error)}</p>
      )}
      {saveText.isSuccess && (
        <p className="mb-2 text-xs text-green-600">Matn saqlandi.</p>
      )}

      {/* Close */}
      <div className="mt-4 border-t border-line pt-3">
        <button
          onClick={onDone}
          className="text-xs font-semibold text-muted hover:text-ink"
        >
          Yopish
        </button>
      </div>

      {deletePage.isError && (
        <p className="mt-2 text-xs text-red-600">
          {apiError(deletePage.error)}
        </p>
      )}
    </div>
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
