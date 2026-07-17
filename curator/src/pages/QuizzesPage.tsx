import { useEffect, useRef, useState } from "react";
import {
  Plus,
  Check,
  X,
  ChevronDown,
  ChevronUp,
  BookOpen,
  Image as ImageIcon,
  Video as VideoIcon,
  Upload,
  Trash2,
  Play,
  Pause,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { useAuth } from "../lib/auth";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import { Reveal, PrimaryButton, SecondaryButton, GlassInput, GlassTextarea, GlassSelect } from "../components/glass";

interface QuizSummary {
  id: string;
  title: string;
  description: string | null;
  difficulty: "easy" | "medium" | "hard";
  status: "draft" | "approved" | "rejected";
  question_count: number;
  category: string | null;
  created_at: string;
  cover_image_url: string | null;
  video_url: string | null;
}

interface QuizQuestion {
  question: string;
  options: string[];
  correct_index: number;
  explanation?: string;
  image_url?: string | null;
  video_url?: string | null;
}

const DIFF_LABEL: Record<string, string> = {
  easy: "Oson",
  medium: "O'rta",
  hard: "Qiyin",
};
const DIFF_COLOR: Record<string, string> = {
  easy: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  medium: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  hard: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
};
const STATUS_COLOR: Record<string, string> = {
  draft: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
  approved: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
  rejected: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
};
const STATUS_LABEL: Record<string, string> = {
  draft: "Kutilmoqda",
  approved: "Tasdiqlangan",
  rejected: "Rad etilgan",
};

export function QuizzesPage() {
  const { role } = useAuth();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const isAdmin = role === "admin";

  const [quizzes, setQuizzes] = useState<QuizSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [quizDetail, setQuizDetail] = useState<{ id: string; questions: QuizQuestion[] } | null>(null);

  const fetchQuizzes = async () => {
    try {
      const endpoint = isAdmin ? "/quizzes/admin/all" : "/quizzes/my/drafts";
      const { data } = await api.get<QuizSummary[]>(endpoint);
      setQuizzes(data);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchQuizzes(); }, []);

  const loadDetail = async (id: string) => {
    if (expandedId === id) {
      setExpandedId(null);
      setQuizDetail(null);
      return;
    }
    const endpoint = isAdmin ? `/quizzes/admin/${id}` : `/quizzes/${id}`;
    const { data } = await api.get(endpoint);
    setExpandedId(id);
    setQuizDetail({ id, questions: data.questions });
  };

  const approve = async (quiz: QuizSummary) => {
    const ok = await confirm({
      title: `"${quiz.title}" testini tasdiqlashni tasdiqlaysizmi?`,
      variant: "primary",
      confirmText: t.modal.approve,
    });
    if (!ok) return;
    try {
      await api.patch(`/quizzes/admin/${quiz.id}/approve`);
      setQuizzes((prev) =>
        prev.map((q) => q.id === quiz.id ? { ...q, status: "approved" } : q)
      );
      toast.success("Test tasdiqlandi.");
    } catch (e) {
      toast.error(apiError(e));
    }
  };

  const reject = async (quiz: QuizSummary) => {
    const ok = await confirm({
      title: `"${quiz.title}" testini rad etishni tasdiqlaysizmi?`,
      variant: "danger",
      confirmText: t.modal.reject,
    });
    if (!ok) return;
    try {
      await api.patch(`/quizzes/admin/${quiz.id}/reject`);
      setQuizzes((prev) =>
        prev.map((q) => q.id === quiz.id ? { ...q, status: "rejected" } : q)
      );
      toast.success("Test rad etildi.");
    } catch (e) {
      toast.error(apiError(e));
    }
  };

  const onMediaChanged = (updated: QuizSummary) => {
    setQuizzes((prev) => prev.map((q) => q.id === updated.id ? updated : q));
  };

  const pendingCount = quizzes.filter((q) => q.status === "draft").length;

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={t.nav.quizzes}
        subtitle={isAdmin ? `${pendingCount} ta test kutilmoqda` : "Testlar yaratish va boshqarish"}
        actions={
          !isAdmin && (
            <PrimaryButton onClick={() => setShowCreate(true)}>
              <Plus size={16} />
              Yangi test
            </PrimaryButton>
          )
        }
      />

      {loading ? (
        <div className="flex h-40 items-center justify-center text-muted">
          Yuklanmoqda…
        </div>
      ) : quizzes.length === 0 ? (
        <div className="flex h-40 flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-line text-muted">
          <BookOpen size={32} strokeWidth={1.5} />
          <span className="text-sm">Hozircha testlar yo'q</span>
          {!isAdmin && (
            <PrimaryButton onClick={() => setShowCreate(true)} className="px-4 py-2 text-xs">
              Birinchi testni yarating
            </PrimaryButton>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {quizzes.map((quiz, qIndex) => (
            <Reveal key={quiz.id} index={qIndex}>
            <div className="overflow-hidden rounded-2xl border border-line bg-card">
              <div className="flex items-center gap-4 p-4">
                <QuizCover
                  url={mediaUrl(quiz.cover_image_url)}
                  fallbackIcon={<BookOpen size={20} className="text-wine dark:text-wine-300" />}
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-bold text-ink truncate">{quiz.title}</span>
                    <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${DIFF_COLOR[quiz.difficulty]}`}>
                      {DIFF_LABEL[quiz.difficulty]}
                    </span>
                    <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${STATUS_COLOR[quiz.status]}`}>
                      {STATUS_LABEL[quiz.status]}
                    </span>
                    {quiz.video_url && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-0.5 text-[11px] font-bold text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
                        <VideoIcon size={11} />
                        Video
                      </span>
                    )}
                    {quiz.cover_image_url && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2 py-0.5 text-[11px] font-bold text-purple-700 dark:bg-purple-900/30 dark:text-purple-400">
                        <ImageIcon size={11} />
                        Rasm
                      </span>
                    )}
                  </div>
                  <div className="mt-1 text-xs text-muted">
                    {quiz.question_count} ta savol
                    {quiz.category && ` · ${quiz.category}`}
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {isAdmin && quiz.status === "draft" && (
                    <>
                      <button
                        onClick={() => approve(quiz)}
                        className="press flex items-center gap-1 rounded-full bg-green-100 px-3 py-1.5 text-xs font-bold text-green-700 transition hover:bg-green-200 dark:bg-green-900/30 dark:text-green-400 dark:hover:bg-green-900/50"
                      >
                        <Check size={14} />
                        Tasdiqlash
                      </button>
                      <button
                        onClick={() => reject(quiz)}
                        className="press flex items-center gap-1 rounded-full bg-red-100 px-3 py-1.5 text-xs font-bold text-red-700 transition hover:bg-red-200 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50"
                      >
                        <X size={14} />
                        Rad etish
                      </button>
                    </>
                  )}
                  <button
                    onClick={() => loadDetail(quiz.id)}
                    className="press flex items-center gap-1 rounded-full border border-line px-3 py-1.5 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine"
                  >
                    {expandedId === quiz.id ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                    Ko'rish
                  </button>
                </div>
              </div>

              {expandedId === quiz.id && quizDetail?.id === quiz.id && (
                <div className="border-t border-line bg-surface px-4 py-4 space-y-4">
                  <QuizMediaEditor
                    quiz={quiz}
                    onChanged={onMediaChanged}
                    canEdit={!isAdmin && quiz.status === "draft"}
                  />
                  <div className="space-y-3">
                    {quizDetail.questions.map((q, qi) => (
                      <div key={qi} className="rounded-xl border border-line bg-card p-4">
                        <p className="font-semibold text-ink">
                          <span className="mr-2 text-wine">{qi + 1}.</span>
                          {q.question}
                        </p>
                        <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
                          {q.options.map((opt, oi) => (
                            <div
                              key={oi}
                              className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${
                                oi === q.correct_index
                                  ? "bg-green-50 text-green-700 font-semibold"
                                  : "bg-surface text-ink"
                              }`}
                            >
                              {oi === q.correct_index && <Check size={14} className="shrink-0" />}
                              <span className={oi !== q.correct_index ? "pl-5" : ""}>{opt}</span>
                            </div>
                          ))}
                        </div>
                        {q.explanation && (
                          <p className="mt-3 text-xs text-muted italic">{q.explanation}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            </Reveal>
          ))}
        </div>
      )}

      {showCreate && (
        <CreateQuizModal
          onClose={() => setShowCreate(false)}
          onCreated={() => { setShowCreate(false); fetchQuizzes(); }}
        />
      )}
    </div>
  );
}

function QuizCover({ url, fallbackIcon }: { url: string | null; fallbackIcon: React.ReactNode }) {
  if (!url) {
    return (
      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-wine/10 dark:bg-wine/15">
        {fallbackIcon}
      </div>
    );
  }
  return (
    <img
      src={url}
      alt=""
      className="h-11 w-11 shrink-0 rounded-xl object-cover"
      onError={(e) => {
        (e.currentTarget as HTMLImageElement).style.display = "none";
      }}
    />
  );
}

function QuizMediaEditor({
  quiz,
  onChanged,
  canEdit,
}: {
  quiz: QuizSummary;
  onChanged: (updated: QuizSummary) => void;
  canEdit: boolean;
}) {
  const imageInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [uploadingVideo, setUploadingVideo] = useState(false);
  const [playing, setPlaying] = useState(false);

  const fullImageUrl = mediaUrl(quiz.cover_image_url);
  const fullVideoUrl = mediaUrl(quiz.video_url);

  const uploadImage = async (file: File) => {
    setUploadingImage(true);
    try {
      const form = new FormData();
      form.append("file", file);
      const { data } = await api.post<QuizSummary>(
        `/quizzes/${quiz.id}/image`,
        form,
      );
      onChanged(data);
    } catch {
      // ignore
    } finally {
      setUploadingImage(false);
    }
  };

  const uploadVideo = async (file: File) => {
    setUploadingVideo(true);
    try {
      const form = new FormData();
      form.append("file", file);
      const { data } = await api.post<QuizSummary>(
        `/quizzes/${quiz.id}/video`,
        form,
      );
      onChanged(data);
    } catch {
      // ignore
    } finally {
      setUploadingVideo(false);
    }
  };

  const togglePlay = () => {
    const el = videoRef.current;
    if (!el) return;
    if (el.paused) { el.play(); setPlaying(true); }
    else { el.pause(); setPlaying(false); }
  };

  return (
    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
      <div className="rounded-xl border border-line bg-card p-4">
        <div className="mb-2 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted">
          <ImageIcon size={13} />
          Muqova rasmi
        </div>
        {fullImageUrl ? (
          <div className="space-y-2">
            <img
              src={fullImageUrl}
              alt=""
              className="h-32 w-full rounded-lg object-cover"
            />
            {canEdit && (
              <button
                onClick={() => imageInputRef.current?.click()}
                disabled={uploadingImage}
                className="press flex w-full items-center justify-center gap-2 rounded-full border border-line px-3 py-2 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine disabled:opacity-50"
              >
                <Upload size={13} />
                {uploadingImage ? "Yuklanmoqda…" : "Almashtirish"}
              </button>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center gap-2 py-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-wine/8">
              <ImageIcon size={26} className="text-wine/60" />
            </div>
            <p className="text-xs text-muted">Rasm yuklanmagan</p>
            {canEdit && (
              <button
                onClick={() => imageInputRef.current?.click()}
                disabled={uploadingImage}
                className="press flex items-center gap-1.5 rounded-full bg-wine px-3 py-1.5 text-xs font-bold text-white hover:bg-wine-dark disabled:opacity-50"
              >
                <Upload size={12} />
                {uploadingImage ? "Yuklanmoqda…" : "Rasm yuklash"}
              </button>
            )}
          </div>
        )}
        {canEdit && (
          <input
            ref={imageInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) uploadImage(file);
              e.target.value = "";
            }}
          />
        )}
      </div>

      <div className="rounded-xl border border-line bg-card p-4">
        <div className="mb-2 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted">
          <VideoIcon size={13} />
          Tushuntirish videosi
        </div>
        {fullVideoUrl ? (
          <div className="space-y-2">
            <div className="relative overflow-hidden rounded-lg bg-black">
              <video
                ref={videoRef}
                src={fullVideoUrl}
                className="h-32 w-full object-cover"
                preload="metadata"
                onPlay={() => setPlaying(true)}
                onPause={() => setPlaying(false)}
                onEnded={() => setPlaying(false)}
              />
              <button
                onClick={togglePlay}
                className="press absolute inset-0 flex items-center justify-center bg-black/30 text-white transition hover:bg-black/50"
              >
                {playing ? <Pause size={28} /> : <Play size={28} />}
              </button>
            </div>
            {canEdit && (
              <button
                onClick={() => videoInputRef.current?.click()}
                disabled={uploadingVideo}
                className="press flex w-full items-center justify-center gap-2 rounded-full border border-line px-3 py-2 text-xs font-semibold text-muted hover:border-wine/30 hover:text-wine disabled:opacity-50"
              >
                <Upload size={13} />
                {uploadingVideo ? "Yuklanmoqda…" : "Almashtirish"}
              </button>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center gap-2 py-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-wine/8">
              <VideoIcon size={26} className="text-wine/60" />
            </div>
            <p className="text-xs text-muted">Video yuklanmagan</p>
            {canEdit && (
              <button
                onClick={() => videoInputRef.current?.click()}
                disabled={uploadingVideo}
                className="press flex items-center gap-1.5 rounded-full bg-wine px-3 py-1.5 text-xs font-bold text-white hover:bg-wine-dark disabled:opacity-50"
              >
                <Upload size={12} />
                {uploadingVideo ? "Yuklanmoqda…" : "Video yuklash"}
              </button>
            )}
          </div>
        )}
        {canEdit && (
          <input
            ref={videoInputRef}
            type="file"
            accept="video/*"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) uploadVideo(file);
              e.target.value = "";
            }}
          />
        )}
      </div>
    </div>
  );
}

function CreateQuizModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [difficulty, setDifficulty] = useState<"easy" | "medium" | "hard">("medium");
  const [category, setCategory] = useState("");
  const [questions, setQuestions] = useState<QuizQuestion[]>([
    { question: "", options: ["", "", "", ""], correct_index: 0, explanation: "" },
  ]);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);
  const [videoPreview, setVideoPreview] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const addQuestion = () =>
    setQuestions((prev) => [
      ...prev,
      { question: "", options: ["", "", "", ""], correct_index: 0, explanation: "" },
    ]);

  const removeQuestion = (i: number) =>
    setQuestions((prev) => prev.filter((_, idx) => idx !== i));

  const updateQuestion = (i: number, key: keyof QuizQuestion, value: unknown) =>
    setQuestions((prev) =>
      prev.map((q, idx) => (idx === i ? { ...q, [key]: value } : q))
    );

  const updateOption = (qi: number, oi: number, value: string) =>
    setQuestions((prev) =>
      prev.map((q, i) => {
        if (i !== qi) return q;
        const options = [...q.options];
        options[oi] = value;
        return { ...q, options };
      })
    );

  const onCoverChange = (file: File | null) => {
    setCoverFile(file);
    if (coverPreview) URL.revokeObjectURL(coverPreview);
    setCoverPreview(file ? URL.createObjectURL(file) : null);
  };

  const onVideoChange = (file: File | null) => {
    setVideoFile(file);
    if (videoPreview) URL.revokeObjectURL(videoPreview);
    setVideoPreview(file ? URL.createObjectURL(file) : null);
  };

  const submit = async () => {
    if (!title.trim()) { setError("Sarlavha kiritilishi shart."); return; }
    const invalid = questions.find((q) => !q.question.trim() || q.options.some((o) => !o.trim()));
    if (invalid) { setError("Barcha savol va variantlarni to'ldiring."); return; }
    const ok = await confirm({
      title: `"${title}" testini yaratishni tasdiqlaysizmi?`,
      description: "Test va unga tegishli barcha savollar saqlanadi.",
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (!ok) return;
    setSaving(true);
    try {
      const { data: created } = await api.post<QuizSummary>("/quizzes", {
        title,
        description: description || null,
        difficulty,
        category: category || null,
        questions: questions.map((q) => ({
          question: q.question,
          options: q.options,
          correct_index: q.correct_index,
          explanation: q.explanation || null,
        })),
      });

      if (coverFile) {
        const form = new FormData();
        form.append("file", coverFile);
        await api.post(`/quizzes/${created.id}/image`, form);
      }
      if (videoFile) {
        const form = new FormData();
        form.append("file", videoFile);
        await api.post(`/quizzes/${created.id}/video`, form);
      }

      toast.success("Test yaratildi.");
      onCreated();
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { detail?: string } } }).response?.data?.detail;
      setError(msg ?? "Xatolik yuz berdi.");
      setSaving(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-10 backdrop-blur-[18px] sm:pt-16"
      style={{ background: "rgba(63,9,24,0.30)" }}
    >
      <div className="animate-sheet-in w-full max-w-2xl overflow-hidden rounded-3xl border border-line bg-card shadow-2xl">
        <div className="flex items-center justify-between border-b border-line px-4 py-4 sm:px-6">
          <h2 className="text-lg font-extrabold text-ink">Yangi test yaratish</h2>
          <button
            onClick={onClose}
            className="press grid h-9 w-9 shrink-0 place-items-center rounded-full border border-line text-muted transition hover:border-wine/30 hover:text-wine"
            aria-label="Yopish"
          >
            <X size={17} />
          </button>
        </div>
        <div className="space-y-5 p-4 sm:p-6">
          {error && (
            <div className="rounded-2xl bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 dark:bg-red-900/20 dark:text-red-400">{error}</div>
          )}

          <div>
            <label className="mb-1.5 block text-sm font-bold text-ink">Sarlavha *</label>
            <GlassInput
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Test sarlavhasi"
            />
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label className="mb-1.5 block text-sm font-bold text-ink">Qiyinlik</label>
              <GlassSelect
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value as "easy" | "medium" | "hard")}
              >
                <option value="easy">Oson</option>
                <option value="medium">O'rta</option>
                <option value="hard">Qiyin</option>
              </GlassSelect>
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-bold text-ink">Kategoriya</label>
              <GlassInput
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                placeholder="Masalan: Nutq, Psixologiya"
              />
            </div>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-bold text-ink">Tavsif</label>
            <GlassTextarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              placeholder="Ixtiyoriy tavsif"
              className="resize-none"
            />
          </div>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <MediaUploader
              label="Muqova rasmi"
              icon={<ImageIcon size={14} />}
              accept="image/*"
              preview={coverPreview}
              onFile={onCoverChange}
              kind="image"
            />
            <MediaUploader
              label="Tushuntirish videosi"
              icon={<VideoIcon size={14} />}
              accept="video/*"
              preview={videoPreview}
              onFile={onVideoChange}
              kind="video"
            />
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-ink">Savollar ({questions.length})</h3>
              <button
                onClick={addQuestion}
                className="press flex items-center gap-1.5 rounded-full border border-line px-3 py-1.5 text-xs font-bold text-wine hover:bg-wine-50 dark:text-wine-300 dark:hover:bg-wine-900/20"
              >
                <Plus size={14} />
                Savol qo'shish
              </button>
            </div>

            {questions.map((q, qi) => (
              <div key={qi} className="rounded-2xl border border-line bg-surface p-4">
                <div className="mb-3 flex items-start justify-between gap-2">
                  <span className="text-sm font-bold text-wine dark:text-wine-300">{qi + 1}-savol</span>
                  {questions.length > 1 && (
                    <button onClick={() => removeQuestion(qi)} className="press rounded-full p-1 text-muted hover:text-red-500 dark:hover:text-red-400">
                      <X size={16} />
                    </button>
                  )}
                </div>
                <GlassInput
                  value={q.question}
                  onChange={(e) => updateQuestion(qi, "question", e.target.value)}
                  placeholder="Savol matni"
                  className="mb-3"
                />
                <div className="mt-1 mb-1 flex items-center gap-1.5">
                  <Check size={13} className="text-green-600 dark:text-green-400" />
                  <span className="text-xs font-semibold text-green-700">To'g'ri javobni belgilash uchun yashil tugmani bosing</span>
                </div>
                <div className="space-y-2">
                  {q.options.map((opt, oi) => {
                    const isCorrect = q.correct_index === oi;
                    const letter = ["A", "B", "C", "D"][oi];
                    return (
                      <div
                        key={oi}
                        className={`flex items-center gap-2 rounded-full border transition-all ${
                          isCorrect
                            ? "border-green-400 bg-green-50 dark:border-green-700 dark:bg-green-900/20"
                            : "border-line bg-card"
                        }`}
                      >
                        <div className={`ml-2 flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-black ${
                          isCorrect ? "bg-green-500 text-white" : "bg-line text-muted"
                        }`}>
                          {letter}
                        </div>

                        <input
                          value={opt}
                          onChange={(e) => updateOption(qi, oi, e.target.value)}
                          placeholder={`${letter} varianti`}
                          className="flex-1 bg-transparent py-2.5 text-sm text-ink outline-none placeholder:text-muted"
                        />

                        <button
                          type="button"
                          onClick={() => updateQuestion(qi, "correct_index", oi)}
                          title="To'g'ri javob sifatida belgilash"
                          className={`press mr-2 flex h-8 w-8 shrink-0 items-center justify-center rounded-full transition-all ${
                            isCorrect
                              ? "bg-green-500 text-white shadow-sm"
                              : "border border-line bg-card text-muted hover:border-green-400 hover:text-green-600 dark:hover:text-green-400"
                          }`}
                        >
                          <Check size={15} strokeWidth={2.5} />
                        </button>
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 border-t border-line px-4 py-4 sm:px-6">
          <SecondaryButton onClick={onClose}>
            Bekor qilish
          </SecondaryButton>
          <PrimaryButton onClick={submit} loading={saving}>
            {saving ? "Saqlanmoqda…" : "Testni yuborish"}
          </PrimaryButton>
        </div>
      </div>
    </div>
  );
}

function MediaUploader({
  label,
  icon,
  accept,
  preview,
  onFile,
  kind,
}: {
  label: string;
  icon: React.ReactNode;
  accept: string;
  preview: string | null;
  onFile: (file: File | null) => void;
  kind: "image" | "video";
}) {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <div>
      <label className="mb-1.5 flex items-center gap-1.5 text-sm font-bold text-ink">
        {icon}
        {label}
      </label>
      {preview ? (
        <div className="relative">
          {kind === "image" ? (
            <img src={preview} alt="" className="h-28 w-full rounded-xl object-cover" />
          ) : (
            <video src={preview} className="h-28 w-full rounded-xl object-cover" controls preload="metadata" />
          )}
          <button
            type="button"
            onClick={() => onFile(null)}
            className="press absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-black/60 text-white transition hover:bg-red-500"
            title="O'chirish"
          >
            <Trash2 size={13} />
          </button>
        </div>
      ) : (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          className="flex w-full items-center justify-center gap-2 rounded-xl border-2 border-dashed border-line bg-surface px-4 py-3 text-sm text-muted transition hover:border-wine/40 hover:text-wine"
        >
          <Upload size={14} />
          Fayl tanlash
        </button>
      )}
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="hidden"
        onChange={(e) => onFile(e.target.files?.[0] ?? null)}
      />
    </div>
  );
}
