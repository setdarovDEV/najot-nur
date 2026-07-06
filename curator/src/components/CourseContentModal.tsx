/**
 * CourseContentModal — full-screen course content manager.
 *
 * Left panel: lesson list with status badges (video ✓, test count, voice ✓)
 * Right panel: selected lesson → Video / Test / Voice-exercise sections
 */
import { useCallback, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  X,
  Plus,
  Trash2,
  Upload,
  CheckCircle2,
  Video,
  ClipboardList,
  Mic,
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  Loader2,
  AlertCircle,
  BookOpen,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { useToast } from "../lib/toast";
import { useConfirm } from "../lib/confirm";
import { useLang } from "../lib/i18n";
import type { AdminCourseDetail, AdminLesson, LessonQuestion } from "../lib/types";

// ─── props ─────────────────────────────────────────────────────────────────

interface Props {
  courseId: string;
  courseTitle: string;
  onClose: () => void;
}

// ─── helpers ───────────────────────────────────────────────────────────────

const fetchCourse = (id: string) =>
  api.get<AdminCourseDetail>(`/admin/courses/${id}`).then((r) => r.data);

// ─── root component ────────────────────────────────────────────────────────

export function CourseContentModal({ courseId, courseTitle, onClose }: Props) {
  const qc = useQueryClient();
  const toast = useToast();
  const confirm = useConfirm();
  const { t } = useLang();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [addingLesson, setAddingLesson] = useState(false);

  const { data: course, isLoading, error } = useQuery({
    queryKey: ["admin", "courses", courseId],
    queryFn: () => fetchCourse(courseId),
  });

  const deleteLessonMut = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/lessons/${id}`),
    onSuccess: (_, id) => {
      qc.invalidateQueries({ queryKey: ["admin", "courses", courseId] });
      qc.invalidateQueries({ queryKey: ["admin", "courses"] });
      if (selectedId === id) setSelectedId(null);
      toast.success("Dars o'chirildi.");
    },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleDeleteLesson(lesson: AdminLesson) {
    const ok = await confirm({
      title: `"${lesson.title}" darsini o'chirishni tasdiqlaysizmi?`,
      description: t.modal.deleteDesc("dars", lesson.title),
      variant: "danger",
      confirmText: t.modal.delete,
    });
    if (ok) deleteLessonMut.mutate(lesson.id);
  }

  const lessons = course?.lessons ?? [];
  const selected = lessons.find((l) => l.id === selectedId) ?? null;

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-surface/95 backdrop-blur-sm">
      {/* ── Header ── */}
      <header className="flex h-14 shrink-0 items-center gap-3 border-b border-line bg-card px-4 shadow-sm sm:gap-4 sm:px-6">
        <BookOpen size={20} className="shrink-0 text-wine" />
        <h2 className="min-w-0 flex-1 truncate text-base font-extrabold text-ink">
          {courseTitle}
        </h2>
        <button
          onClick={onClose}
          className="flex h-9 w-9 items-center justify-center rounded-xl border border-line text-muted transition hover:border-wine/30 hover:text-wine"
        >
          <X size={18} />
        </button>
      </header>

      {/* ── Body ── */}
      <div className="flex min-h-0 flex-1">
        {/* ── Left sidebar: lesson list ── */}
        <aside className={`flex-col border-r border-line bg-card ${
          selectedId
            ? "hidden md:flex md:w-72 md:shrink-0"
            : "flex w-full md:w-72 md:shrink-0"
        }`}>
          <div className="flex items-center justify-between px-4 py-3">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Darslar ({lessons.length})
            </span>
            <button
              onClick={() => setAddingLesson((v) => !v)}
              className="flex items-center gap-1 rounded-lg bg-wine px-2.5 py-1 text-[11px] font-bold text-white hover:bg-wine/90"
            >
              <Plus size={12} />
              Dars
            </button>
          </div>

          {addingLesson && (
            <AddLessonInline
              courseId={courseId}
              onDone={(newId) => {
                setAddingLesson(false);
                qc.invalidateQueries({ queryKey: ["admin", "courses", courseId] });
                qc.invalidateQueries({ queryKey: ["admin", "courses"] });
                setSelectedId(newId);
              }}
              onCancel={() => setAddingLesson(false)}
            />
          )}

          <div className="flex-1 overflow-y-auto pb-4">
            {isLoading && (
              <div className="flex items-center gap-2 px-4 py-6 text-sm text-muted">
                <Loader2 size={15} className="animate-spin" />
                Yuklanmoqda…
              </div>
            )}
            {error && (
              <div className="flex items-center gap-2 px-4 py-6 text-sm text-red-500">
                <AlertCircle size={15} />
                Xatolik yuz berdi
              </div>
            )}
            {lessons.map((l, i) => (
              <LessonSidebarItem
                key={l.id}
                lesson={l}
                index={i + 1}
                isActive={l.id === selectedId}
                onSelect={() => setSelectedId(l.id)}
                onDelete={() => handleDeleteLesson(l)}
              />
            ))}
            {!isLoading && lessons.length === 0 && (
              <p className="px-4 py-6 text-center text-sm text-muted">
                Hali dars yo'q.
                <br />
                "Dars" tugmasi bilan qo'shing.
              </p>
            )}
          </div>
        </aside>

        {/* ── Right: lesson detail ── */}
        <main className="min-w-0 flex-1 overflow-y-auto">
          {selected ? (
            <LessonDetail
              key={selected.id}
              lesson={selected}
              courseId={courseId}
              onRefresh={() =>
                qc.invalidateQueries({ queryKey: ["admin", "courses", courseId] })
              }
              onBack={() => setSelectedId(null)}
            />
          ) : (
            <div className="hidden h-full flex-col items-center justify-center gap-3 text-muted md:flex">
              <BookOpen size={40} className="opacity-30" />
              <p className="text-sm">Darsni tanlang yoki yangi dars qo'shing</p>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

// ─── Sidebar item ───────────────────────────────────────────────────────────

function LessonSidebarItem({
  lesson,
  index,
  isActive,
  onSelect,
  onDelete,
}: {
  lesson: AdminLesson;
  index: number;
  isActive: boolean;
  onSelect: () => void;
  onDelete: () => void;
}) {
  return (
    <button
      onClick={onSelect}
      className={`group flex w-full items-center gap-3 px-4 py-3 text-left transition ${
        isActive
          ? "border-r-2 border-wine bg-wine/5"
          : "hover:bg-surface"
      }`}
    >
      <span
        className={`grid h-7 w-7 shrink-0 place-items-center rounded-lg text-xs font-black ${
          isActive ? "bg-wine text-white" : "bg-wine/10 text-wine"
        }`}
      >
        {index}
      </span>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold text-ink">{lesson.title}</div>
        <div className="mt-0.5 flex items-center gap-2">
          {lesson.video_url ? (
            <span title="Video yuklangan" className="text-green-500">
              <Video size={11} />
            </span>
          ) : (
            <span title="Video yo'q" className="text-yellow-500">
              <Video size={11} />
            </span>
          )}
          {lesson.questions.length > 0 && (
            <span className="text-[10px] font-bold text-wine">
              {lesson.questions.length}t
            </span>
          )}
          {lesson.is_voice_exercise && (
            <Mic size={11} className="text-purple-500" />
          )}
        </div>
      </div>
      <button
        onClick={(e) => { e.stopPropagation(); onDelete(); }}
        className="hidden h-6 w-6 shrink-0 items-center justify-center rounded-lg text-red-400 hover:bg-red-50 group-hover:flex dark:hover:bg-red-900/20"
      >
        <Trash2 size={12} />
      </button>
    </button>
  );
}

// ─── Add lesson inline ──────────────────────────────────────────────────────

function AddLessonInline({
  courseId,
  onDone,
  onCancel,
}: {
  courseId: string;
  onDone: (newId: string) => void;
  onCancel: () => void;
}) {
  const toast = useToast();
  const confirm = useConfirm();
  const { t } = useLang();
  const [title, setTitle] = useState("");
  const mut = useMutation({
    mutationFn: () =>
      api.post(`/admin/courses/${courseId}/lessons`, { title: title.trim() }),
    onSuccess: (res) => onDone(res.data.id),
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleCreate() {
    if (!title.trim()) return;
    const ok = await confirm({
      title: t.modal.createTitle("dars"),
      description: `"${title.trim()}" — ${t.modal.createDesc("Dars")}`,
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (ok) mut.mutate();
  }

  return (
    <div className="mx-3 mb-2 rounded-xl border border-wine/30 bg-surface p-3">
      <input
        autoFocus
        placeholder="Dars nomi…"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && title.trim()) handleCreate();
          if (e.key === "Escape") onCancel();
        }}
        className="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine"
      />
      <div className="mt-2 flex gap-2">
        <button
          onClick={handleCreate}
          disabled={mut.isPending || !title.trim()}
          className="rounded-lg bg-wine px-3 py-1.5 text-xs font-bold text-white disabled:opacity-50"
        >
          {mut.isPending ? "…" : "Qo'shish"}
        </button>
        <button
          onClick={onCancel}
          className="rounded-lg border border-line px-3 py-1.5 text-xs text-muted"
        >
          Bekor
        </button>
      </div>
    </div>
  );
}

// ─── Lesson detail (right panel) ───────────────────────────────────────────

function LessonDetail({
  lesson,
  courseId,
  onRefresh,
  onBack,
}: {
  lesson: AdminLesson;
  courseId: string;
  onRefresh: () => void;
  onBack?: () => void;
}) {
  const toast = useToast();

  const updateMut = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      api.patch(`/admin/lessons/${lesson.id}`, payload),
    onSuccess: onRefresh,
    onError: (e) => toast.error(apiError(e)),
  });

  return (
    <div className="mx-auto max-w-3xl px-4 py-4 sm:px-6 sm:py-6">
      {/* ← Back button — mobile only */}
      {onBack && (
        <button
          onClick={onBack}
          className="mb-3 flex items-center gap-1.5 text-sm font-semibold text-wine md:hidden"
        >
          <ChevronLeft size={16} />
          Darslar ro'yxati
        </button>
      )}
      {/* ── Lesson title ── */}
      <LessonTitleEditor
        lesson={lesson}
        onSave={(title) => updateMut.mutate({ title })}
      />

      <div className="mt-6 flex flex-col gap-5">
        {/* Section 1: Video */}
        <VideoSection lesson={lesson} onRefresh={onRefresh} />

        {/* Section 2: Test questions */}
        <TestSection lesson={lesson} courseId={courseId} onRefresh={onRefresh} />

        {/* Section 3: Voice exercise */}
        <VoiceSection lesson={lesson} onSave={(p) => updateMut.mutate(p)} />
      </div>
    </div>
  );
}

// ─── Lesson title editor ────────────────────────────────────────────────────

function LessonTitleEditor({
  lesson,
  onSave,
}: {
  lesson: AdminLesson;
  onSave: (title: string) => void;
}) {
  const confirm = useConfirm();
  const { t } = useLang();
  const [editing, setEditing] = useState(false);
  const [title, setTitle] = useState(lesson.title);

  async function handleSave() {
    if (!title.trim()) return;
    const ok = await confirm({
      title: t.modal.updateTitle("dars"),
      description: t.modal.updateDesc("Dars"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (ok) {
      onSave(title.trim());
      setEditing(false);
    }
  }

  if (!editing) {
    return (
      <button
        onClick={() => setEditing(true)}
        className="group flex items-center gap-2 text-left"
      >
        <h3 className="text-lg font-extrabold text-ink group-hover:text-wine sm:text-xl">
          {lesson.title}
        </h3>
        <span className="rounded-md border border-line px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-muted opacity-0 transition group-hover:opacity-100">
          Tahrirlash
        </span>
      </button>
    );
  }

  return (
    <div className="flex flex-col gap-2 sm:flex-row">
      <input
        autoFocus
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && title.trim()) handleSave();
          if (e.key === "Escape") setEditing(false);
        }}
        className="flex-1 rounded-xl border border-wine/40 bg-card px-4 py-2 text-base font-bold text-ink outline-none focus:ring-2 focus:ring-wine/10 sm:text-lg"
      />
      <div className="flex gap-2">
        <button
          onClick={handleSave}
          className="flex-1 rounded-xl bg-wine px-4 py-2 text-sm font-bold text-white sm:flex-none"
        >
          Saqlash
        </button>
        <button
          onClick={() => setEditing(false)}
          className="flex-1 rounded-xl border border-line px-4 py-2 text-sm text-muted sm:flex-none"
        >
          Bekor
        </button>
      </div>
    </div>
  );
}

// ─── Video section ──────────────────────────────────────────────────────────

function VideoSection({
  lesson,
  onRefresh,
}: {
  lesson: AdminLesson;
  onRefresh: () => void;
}) {
  const toast = useToast();
  const [progress, setProgress] = useState<number | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const upload = useCallback(
    async (file: File) => {
      if (!file.type.startsWith("video/")) {
        toast.error("Faqat video fayl yuklash mumkin.");
        return;
      }
      setProgress(0);
      const fd = new FormData();
      fd.append("file", file);
      try {
        await api.post(`/admin/lessons/${lesson.id}/video`, fd, {
          headers: { "Content-Type": "multipart/form-data" },
          onUploadProgress: (evt) => {
            if (evt.total) setProgress(Math.round((evt.loaded / evt.total) * 100));
          },
        });
        toast.success("Video muvaffaqiyatli yuklandi.");
        onRefresh();
      } catch (e) {
        toast.error(apiError(e));
      } finally {
        setProgress(null);
        if (inputRef.current) inputRef.current.value = "";
      }
    },
    [lesson.id, onRefresh, toast]
  );

  const [dragging, setDragging] = useState(false);

  return (
    <CollapsibleSection
      icon={<Video size={17} className="text-wine" />}
      title="Video dars"
      badge={lesson.video_url ? <StatusBadge ok>Yuklangan</StatusBadge> : <StatusBadge>Yuklanmagan</StatusBadge>}
      defaultOpen
    >
      <input
        ref={inputRef}
        type="file"
        accept="video/*"
        className="hidden"
        onChange={(e) => { const f = e.target.files?.[0]; if (f) upload(f); }}
      />

      {lesson.video_url ? (
        <div className="flex flex-col gap-3">
          <video
            src={mediaUrl(lesson.video_url) ?? ""}
            controls
            className="max-h-56 w-full rounded-xl border border-line bg-black object-contain"
          />
          <button
            onClick={() => inputRef.current?.click()}
            disabled={progress !== null}
            className="flex items-center gap-2 rounded-xl border border-wine/40 px-4 py-2 text-sm font-semibold text-wine hover:bg-wine/5 disabled:opacity-50"
          >
            <Upload size={14} />
            Videoni almashtirish
          </button>
          {progress !== null && <ProgressBar value={progress} />}
        </div>
      ) : (
        <div
          onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragging(false);
            const f = e.dataTransfer.files[0];
            if (f) upload(f);
          }}
          onClick={() => inputRef.current?.click()}
          className={`flex cursor-pointer flex-col items-center gap-3 rounded-2xl border-2 border-dashed p-6 transition sm:p-10 ${
            dragging
              ? "border-wine bg-wine/5"
              : "border-line hover:border-wine/40 hover:bg-surface"
          }`}
        >
          <Upload size={30} className="text-wine/60 dark:text-wine-300" />
          <div className="text-center text-sm text-muted">
            <span className="font-semibold text-wine">Fayl tanlash</span> yoki bu yerga tashlang
            <br />
            <span className="text-xs">MP4, MOV, AVI — 2 GB gacha</span>
          </div>
          {progress !== null && <ProgressBar value={progress} />}
        </div>
      )}
    </CollapsibleSection>
  );
}

// ─── Test questions section ─────────────────────────────────────────────────

function TestSection({
  lesson,
  onRefresh,
}: {
  lesson: AdminLesson;
  courseId?: string;
  onRefresh: () => void;
}) {
  const toast = useToast();
  const confirm = useConfirm();
  const { t } = useLang();
  const [showForm, setShowForm] = useState(false);

  const deleteMut = useMutation({
    mutationFn: (qId: string) =>
      api.delete(`/admin/lessons/${lesson.id}/questions/${qId}`),
    onSuccess: () => { toast.success("Savol o'chirildi."); onRefresh(); },
    onError: (e) => toast.error(apiError(e)),
  });

  async function handleDelete(q: LessonQuestion) {
    const ok = await confirm({
      title: "Bu savolni o'chirishni tasdiqlaysizmi?",
      description: `"${q.question}" — ${t.modal.deleteDesc("savol", q.question)}`,
      variant: "danger",
      confirmText: t.modal.delete,
    });
    if (ok) deleteMut.mutate(q.id);
  }

  return (
    <CollapsibleSection
      icon={<ClipboardList size={17} className="text-wine" />}
      title="Test savollari"
      badge={
        lesson.questions.length > 0 ? (
          <StatusBadge ok>{lesson.questions.length} ta savol</StatusBadge>
        ) : (
          <StatusBadge>Savollar yo'q</StatusBadge>
        )
      }
      defaultOpen={lesson.questions.length > 0}
    >
      <div className="flex flex-col gap-3">
        {lesson.questions.map((q, i) => (
          <QuestionCard
            key={q.id}
            q={q}
            index={i + 1}
            onDelete={() => handleDelete(q)}
          />
        ))}

        {showForm ? (
          <AddQuestionForm
            lessonId={lesson.id}
            onDone={() => { setShowForm(false); onRefresh(); }}
            onCancel={() => setShowForm(false)}
          />
        ) : (
          <button
            onClick={() => setShowForm(true)}
            className="flex items-center gap-2 rounded-xl border border-dashed border-wine/40 px-4 py-3 text-sm font-semibold text-wine hover:bg-wine/5"
          >
            <Plus size={15} />
            Savol qo'shish
          </button>
        )}
      </div>
    </CollapsibleSection>
  );
}

function QuestionCard({
  q,
  index,
  onDelete,
}: {
  q: LessonQuestion;
  index: number;
  onDelete: () => void;
}) {
  return (
    <div className="rounded-xl border border-line bg-surface p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-2">
          <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-wine/10 text-xs font-black text-wine">
            {index}
          </span>
          <p className="text-sm font-semibold text-ink">{q.question}</p>
        </div>
        <button
          onClick={onDelete}
          className="shrink-0 rounded-lg p-1 text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
        >
          <Trash2 size={13} />
        </button>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-1.5 pl-8">
        {q.options.map((opt, i) => (
          <div
            key={i}
            className={`rounded-lg px-3 py-1.5 text-xs font-semibold ${
              i === q.correct_index
                ? "bg-green-100 text-green-700 ring-1 ring-green-300 dark:bg-green-900/30 dark:text-green-400"
                : "bg-card text-muted ring-1 ring-line"
            }`}
          >
            {i === q.correct_index && "✓ "}
            {opt}
          </div>
        ))}
      </div>
    </div>
  );
}

function AddQuestionForm({
  lessonId,
  onDone,
  onCancel,
}: {
  lessonId: string;
  onDone: () => void;
  onCancel: () => void;
}) {
  const toast = useToast();
  const confirm = useConfirm();
  const { t } = useLang();
  const [question, setQuestion] = useState("");
  const [options, setOptions] = useState(["", "", "", ""]);
  const [correctIndex, setCorrectIndex] = useState(0);

  const mut = useMutation({
    mutationFn: () =>
      api.post(`/admin/lessons/${lessonId}/questions`, {
        question: question.trim(),
        options: options.filter((o) => o.trim()),
        correct_index: correctIndex,
      }),
    onSuccess: () => {
      toast.success("Savol qo'shildi.");
      onDone();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const validOptions = options.filter((o) => o.trim());
  const canSubmit = question.trim().length > 0 && validOptions.length >= 2;

  async function handleAdd() {
    if (!canSubmit) return;
    const ok = await confirm({
      title: t.modal.createTitle("savol"),
      description: t.modal.createDesc("Savol"),
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (ok) mut.mutate();
  }

  return (
    <div className="rounded-xl border border-wine/20 bg-wine/5 p-4">
      <p className="mb-3 text-xs font-bold uppercase tracking-wide text-muted">
        Yangi savol
      </p>
      <textarea
        placeholder="Savol matni…"
        value={question}
        onChange={(e) => setQuestion(e.target.value)}
        rows={2}
        className="w-full rounded-xl border border-line bg-card px-3 py-2 text-sm text-ink outline-none focus:border-wine/40"
      />
      <p className="mb-2 mt-3 text-xs font-semibold text-muted">
        Javob variantlari (to'g'ri javobni belgilang):
      </p>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        {options.map((opt, i) => (
          <label key={i} className="flex items-center gap-2">
            <input
              type="radio"
              name={`correct-${lessonId}`}
              checked={correctIndex === i}
              onChange={() => setCorrectIndex(i)}
              className="accent-wine"
            />
            <input
              placeholder={`${i + 1}-variant`}
              value={opt}
              onChange={(e) => {
                const next = [...options];
                next[i] = e.target.value;
                setOptions(next);
              }}
              className="flex-1 rounded-lg border border-line bg-card px-2.5 py-1.5 text-sm text-ink outline-none focus:border-wine/40"
            />
          </label>
        ))}
      </div>
      <div className="mt-3 flex gap-2">
        <button
          onClick={handleAdd}
          disabled={mut.isPending || !canSubmit}
          className="flex items-center gap-1.5 rounded-xl bg-wine px-4 py-2 text-sm font-bold text-white disabled:opacity-50"
        >
          {mut.isPending ? <Loader2 size={14} className="animate-spin" /> : <CheckCircle2 size={14} />}
          Qo'shish
        </button>
        <button
          onClick={onCancel}
          className="rounded-xl border border-line px-4 py-2 text-sm text-muted"
        >
          Bekor
        </button>
      </div>
    </div>
  );
}

// ─── Voice exercise section ─────────────────────────────────────────────────

function VoiceSection({
  lesson,
  onSave,
}: {
  lesson: AdminLesson;
  onSave: (p: Record<string, unknown>) => void;
}) {
  const { t } = useLang();
  const confirm = useConfirm();
  const [enabled, setEnabled] = useState(lesson.is_voice_exercise);
  const [prompt, setPrompt] = useState(lesson.voice_exercise_prompt ?? "");
  const [dirty, setDirty] = useState(false);

  async function handleSave() {
    const ok = await confirm({
      title: t.modal.updateTitle("dars"),
      description: t.modal.updateDesc("Dars"),
      variant: "primary",
      confirmText: t.modal.save,
    });
    if (ok) {
      onSave({ is_voice_exercise: enabled, voice_exercise_prompt: prompt });
      setDirty(false);
    }
  }

  return (
    <CollapsibleSection
      icon={<Mic size={17} className="text-purple-500" />}
      title="Nutq mashqi"
      badge={
        enabled ? (
          <StatusBadge ok>Yoqilgan</StatusBadge>
        ) : (
          <StatusBadge>O'chirilgan</StatusBadge>
        )
      }
      defaultOpen={lesson.is_voice_exercise}
    >
      <div className="flex flex-col gap-4">
        <label className="flex cursor-pointer items-center gap-3">
          <div
            onClick={() => { setEnabled((v) => !v); setDirty(true); }}
            className={`relative h-6 w-11 rounded-full transition ${enabled ? "bg-wine" : "bg-line"}`}
          >
            <div
              className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${
                enabled ? "left-5" : "left-0.5"
              }`}
            />
          </div>
          <span className="text-sm font-semibold text-ink">
            {enabled ? "Nutq mashqi yoqilgan" : "Nutq mashqi o'chirilgan"}
          </span>
        </label>

        {enabled && (
          <div>
            <label className="mb-1 block text-xs font-bold uppercase tracking-wide text-muted">
              Mashq matni / ko'rsatma
            </label>
            <textarea
              value={prompt}
              onChange={(e) => { setPrompt(e.target.value); setDirty(true); }}
              rows={4}
              placeholder="Masalan: Quyidagi gapni baland ovozda va aniq talaffuz qilib o'qing…"
              className="w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
            />
          </div>
        )}

        {dirty && (
          <div className="flex gap-2">
            <button
              onClick={handleSave}
              className="flex items-center gap-1.5 rounded-xl bg-wine px-4 py-2 text-sm font-bold text-white"
            >
              <CheckCircle2 size={14} />
              Saqlash
            </button>
            <button
              onClick={() => {
                setEnabled(lesson.is_voice_exercise);
                setPrompt(lesson.voice_exercise_prompt ?? "");
                setDirty(false);
              }}
              className="rounded-xl border border-line px-4 py-2 text-sm text-muted"
            >
              Bekor
            </button>
          </div>
        )}
      </div>
    </CollapsibleSection>
  );
}

// ─── Shared UI primitives ───────────────────────────────────────────────────

function CollapsibleSection({
  icon,
  title,
  badge,
  children,
  defaultOpen = false,
}: {
  icon: React.ReactNode;
  title: string;
  badge?: React.ReactNode;
  children: React.ReactNode;
  defaultOpen?: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <div className="overflow-hidden rounded-2xl border border-line bg-card">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center gap-3 px-4 py-3 text-left transition hover:bg-surface sm:px-5 sm:py-4"
      >
        {icon}
        <span className="flex-1 text-sm font-extrabold text-ink">{title}</span>
        {badge}
        {open ? (
          <ChevronUp size={16} className="shrink-0 text-muted" />
        ) : (
          <ChevronDown size={16} className="shrink-0 text-muted" />
        )}
      </button>
      {open && <div className="border-t border-line px-4 pb-4 pt-3 sm:px-5 sm:pb-5 sm:pt-4">{children}</div>}
    </div>
  );
}

function StatusBadge({
  ok,
  children,
}: {
  ok?: boolean;
  children: React.ReactNode;
}) {
  return (
    <span
      className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
        ok
          ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
          : "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-500"
      }`}
    >
      {children}
    </span>
  );
}

function ProgressBar({ value }: { value: number }) {
  return (
    <div className="w-full">
      <div className="mb-1 flex justify-between text-xs text-muted">
        <span>Yuklanmoqda…</span>
        <span>{value}%</span>
      </div>
      <div className="h-2 w-full overflow-hidden rounded-full bg-line">
        <div
          className="h-full rounded-full bg-wine transition-all duration-300"
          style={{ width: `${value}%` }}
        />
      </div>
    </div>
  );
}
