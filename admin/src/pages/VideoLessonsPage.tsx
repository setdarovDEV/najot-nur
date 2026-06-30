import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Trash2,
  Video,
  Eye,
  EyeOff,
  Lock,
  Settings2,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import type { AdminCourse } from "../lib/types";
import { CourseContentModal } from "../components/CourseContentModal";

// ─── API helpers ────────────────────────────────────────────────────────────

const fetchCourses = () =>
  api.get<AdminCourse[]>("/admin/courses").then((r) => r.data);

// ─── Main page ───────────────────────────────────────────────────────────────

export function VideoLessonsPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const confirm = useConfirm();
  const canEdit = true;
  const [creating, setCreating] = useState(false);
  const [managingCourse, setManagingCourse] = useState<AdminCourse | null>(null);

  const { data: courses = [], isLoading } = useQuery({
    queryKey: ["admin", "courses"],
    queryFn: fetchCourses,
  });

  const deleteCourse = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/courses/${id}`),
    onSuccess: () => {
      toast.success(t.videoLessons.deleteSuccess);
      qc.invalidateQueries({ queryKey: ["admin", "courses"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const togglePublish = useMutation({
    mutationFn: ({ id, value }: { id: string; value: boolean }) =>
      api.patch(`/admin/courses/${id}`, { is_published: value }),
    onSuccess: () => {
      toast.success(t.videoLessons.toggleSuccess);
      qc.invalidateQueries({ queryKey: ["admin", "courses"] });
    },
    onError: (e) => toast.error(apiError(e)),
  });

  return (
    <div className="p-8">
      <PageHeader
        title={t.videoLessons.title}
        subtitle={
          canEdit
            ? "Kurslar va video darslarni boshqarish"
            : "Faqat ko'rish rejimi — kontent kurator tomonidan boshqariladi"
        }
        actions={
          canEdit ? (
            <button
              onClick={() => setCreating(true)}
              className="flex items-center gap-2 rounded-xl bg-wine px-5 py-2.5 text-sm font-semibold text-white hover:bg-wine/90"
            >
              <Plus size={16} />
              Kurs yaratish
            </button>
          ) : (
            <span className="flex items-center gap-2 rounded-xl border border-line bg-card px-4 py-2 text-xs font-semibold text-muted">
              <Lock size={14} />
              Faqat ko'rish
            </span>
          )
        }
      />

      {creating && canEdit && (
        <CreateCourseForm
          onClose={() => setCreating(false)}
          onCreated={(id) => {
            setCreating(false);
            const created = { id } as AdminCourse;
            qc.invalidateQueries({ queryKey: ["admin", "courses"] });
            // immediately open the content manager for the new course
            setManagingCourse({ ...created, title: "Yangi kurs" } as AdminCourse);
          }}
        />
      )}

      {isLoading ? (
        <div className="py-20 text-center text-muted">Yuklanmoqda...</div>
      ) : courses.length === 0 ? (
        <div className="py-20 text-center text-muted">
          Hali kurs mavjud emas. Birinchi kursni yarating.
        </div>
      ) : (
        <div className="space-y-3">
          {courses.map((c) => (
            <div
              key={c.id}
              className="overflow-hidden rounded-2xl border border-line bg-card"
            >
              <div className="flex items-center gap-4 p-4">
                {c.cover_url ? (
                  <img
                    src={mediaUrl(c.cover_url)!}
                    alt={c.title}
                    className="h-14 w-20 rounded-xl object-cover"
                  />
                ) : (
                  <div className="grid h-14 w-20 place-items-center rounded-xl bg-wine/10">
                    <Video size={22} className="text-wine/60" />
                  </div>
                )}

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-ink truncate">{c.title}</span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                        c.is_published
                          ? "bg-green-100 text-green-700"
                          : "bg-yellow-100 text-yellow-700"
                      }`}
                    >
                      {c.is_published ? "Chiqarilgan" : "Qoralama"}
                    </span>
                  </div>
                  <div className="mt-0.5 text-xs text-muted">
                    {c.lesson_count} ta dars · {c.level} ·{" "}
                    {Number(c.price) > 0
                      ? `${Number(c.price).toLocaleString()} so'm`
                      : "Bepul"}
                  </div>
                </div>

                {canEdit && (
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => setManagingCourse(c)}
                      className="flex items-center gap-1.5 rounded-xl bg-wine px-3 py-2 text-xs font-bold text-white hover:bg-wine/90"
                      title="Kurs kontentini boshqarish"
                    >
                      <Settings2 size={14} />
                      Boshqarish
                    </button>
                    <button
                      title={c.is_published ? "Yashirish" : "Nashr qilish"}
                      onClick={async () => {
                        const ok = await confirm({
                          title: c.is_published
                            ? t.videoLessons.confirmUnpublish(c.title)
                            : t.videoLessons.confirmPublish(c.title),
                          variant: c.is_published ? "warning" : "primary",
                          confirmText: c.is_published
                            ? t.modal.unpublish
                            : t.modal.publish,
                        });
                        if (ok)
                          togglePublish.mutate({
                            id: c.id,
                            value: !c.is_published,
                          });
                      }}
                      className="rounded-lg p-2 text-muted hover:bg-surface"
                    >
                      {c.is_published ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                    <button
                      title="O'chirish"
                      onClick={async () => {
                        const ok = await confirm({
                          title: t.videoLessons.confirmDelete(c.title),
                          description: t.modal.deleteDesc("kurs", c.title),
                          variant: "danger",
                          confirmText: t.modal.delete,
                        });
                        if (ok) deleteCourse.mutate(c.id);
                      }}
                      className="rounded-lg p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {managingCourse && (
        <CourseContentModal
          courseId={managingCourse.id}
          courseTitle={managingCourse.title}
          onClose={() => {
            setManagingCourse(null);
            qc.invalidateQueries({ queryKey: ["admin", "courses"] });
          }}
        />
      )}
    </div>
  );
}

// ─── Create course form ──────────────────────────────────────────────────────

function CreateCourseForm({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: (id: string) => void;
}) {
  const { t } = useLang();
  const confirm = useConfirm();
  const toast = useToast();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("0");
  const [level, setLevel] = useState("beginner");
  const [saving, setSaving] = useState(false);

  async function handleConfirmCreate() {
    if (!title.trim()) return;
    const ok = await confirm({
      title: t.modal.createTitle("kurs"),
      description: t.modal.createDesc("Kurs"),
      variant: "primary",
      confirmText: t.modal.create,
    });
    if (!ok) return;
    setSaving(true);
    try {
      const { data } = await api.post("/admin/courses", {
        title: title.trim(),
        description: description.trim() || null,
        price: parseFloat(price) || 0,
        level,
      });
      toast.success(t.videoLessons.createSuccess);
      onCreated(data.id);
    } catch (e) {
      toast.error(apiError(e));
    } finally {
      setSaving(false);
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    await handleConfirmCreate();
  }

  return (
    <form
      onSubmit={submit}
      className="mb-6 rounded-2xl border border-wine/30 bg-card p-5"
    >
      <div className="mb-4 font-semibold text-ink">Yangi kurs</div>
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="flex flex-col gap-1 sm:col-span-2">
          <span className="text-xs font-semibold text-muted">Kurs nomi</span>
          <input
            required
            placeholder="Masalan: Nutq san'ati"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine"
          />
        </label>
        <label className="flex flex-col gap-1 sm:col-span-2">
          <span className="text-xs font-semibold text-muted">Tavsif</span>
          <textarea
            placeholder="Kurs haqida qisqacha..."
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={2}
            className="rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine"
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-xs font-semibold text-muted">Narxi (so'm)</span>
          <input
            type="number"
            min="0"
            placeholder="0"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            className="rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine"
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-xs font-semibold text-muted">Daraja</span>
          <select
            value={level}
            onChange={(e) => setLevel(e.target.value)}
            className="rounded-xl border border-line bg-card px-4 py-2.5 text-sm text-ink outline-none focus:border-wine"
          >
            <option value="beginner">Boshlang'ich</option>
            <option value="intermediate">O'rta</option>
            <option value="advanced">Yuqori</option>
          </select>
        </label>
      </div>
      <div className="mt-4 flex gap-2">
        <button
          type="submit"
          disabled={saving}
          className="rounded-xl bg-wine px-5 py-2 text-sm font-semibold text-white disabled:opacity-50"
        >
          {saving ? "Saqlanmoqda..." : "Yaratish"}
        </button>
        <button
          type="button"
          onClick={onClose}
          className="rounded-xl border border-line px-5 py-2 text-sm font-semibold text-muted"
        >
          Bekor qilish
        </button>
      </div>
    </form>
  );
}

