import { useRef, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Trash2,
  Video,
  Eye,
  EyeOff,
  Lock,
  Settings2,
  Pencil,
  Upload,
} from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useConfirm } from "../lib/confirm";
import { useToast } from "../lib/toast";
import type { AdminCourse } from "../lib/types";
import { CourseContentModal } from "../components/CourseContentModal";
import {
  Modal,
  ModalBody,
  ModalCancelButton,
  ModalFooter,
  ModalHeader,
  ModalSubmitButton,
} from "../components/Modal";
import {
  Reveal,
  PrimaryButton,
  GlassInput,
  GlassTextarea,
  GlassSelect,
  StatusPill,
} from "../components/glass";

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
  const [showCreate, setShowCreate] = useState(false);
  const [editingCourse, setEditingCourse] = useState<AdminCourse | null>(null);
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
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={t.videoLessons.title}
        subtitle={
          canEdit
            ? "Kurslar va video darslarni boshqarish"
            : "Faqat ko'rish rejimi — kontent kurator tomonidan boshqariladi"
        }
        actions={
          canEdit ? (
            <PrimaryButton onClick={() => setShowCreate(true)}>
              <Plus size={16} />
              Kurs yaratish
            </PrimaryButton>
          ) : (
            <span className="flex items-center gap-2 rounded-full border border-line bg-card px-4 py-2 text-xs font-semibold text-muted">
              <Lock size={14} />
              Faqat ko'rish
            </span>
          )
        }
      />

      {showCreate && canEdit && (
        <CourseModal
          onClose={() => setShowCreate(false)}
          onCreated={(id) => {
            setShowCreate(false);
            qc.invalidateQueries({ queryKey: ["admin", "courses"] });
            setManagingCourse({ id, title: "Yangi kurs" } as AdminCourse);
          }}
        />
      )}

      {editingCourse && canEdit && (
        <CourseModal
          initial={editingCourse}
          onClose={() => setEditingCourse(null)}
          onCreated={() => {
            setEditingCourse(null);
            qc.invalidateQueries({ queryKey: ["admin", "courses"] });
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
          {courses.map((c, i) => (
            <Reveal key={c.id} index={i}>
              <div className="overflow-hidden rounded-2xl border border-line bg-card">
                <div className="flex items-center gap-4 p-4">
                  {c.cover_url ? (
                    <img
                      src={mediaUrl(c.cover_url)!}
                      alt={c.title}
                      className="h-14 w-20 rounded-xl object-cover"
                    />
                  ) : (
                    <div className="grid h-14 w-20 place-items-center rounded-xl bg-wine/10 dark:bg-wine/15">
                      <Video size={22} className="text-wine/60 dark:text-wine-300" />
                    </div>
                  )}

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-ink truncate">{c.title}</span>
                      <StatusPill tone={c.is_published ? "success" : "warning"}>
                        {c.is_published ? "Chiqarilgan" : "Qoralama"}
                      </StatusPill>
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
                        className="press flex items-center gap-1.5 rounded-full bg-wine px-2 py-2 text-xs font-bold text-white hover:bg-wine/90 sm:px-3"
                        title="Kurs kontentini boshqarish"
                      >
                        <Settings2 size={14} />
                        <span className="hidden sm:inline">Boshqarish</span>
                      </button>
                      <button
                        onClick={() => setEditingCourse(c)}
                        className="press rounded-full p-2 text-muted hover:bg-surface"
                        title="Tahrirlash"
                      >
                        <Pencil size={16} />
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
                        className="press rounded-full p-2 text-muted hover:bg-surface"
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
                        className="press rounded-full p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </Reveal>
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

// ─── Create / Edit course modal ──────────────────────────────────────────────

function CourseModal({
  initial,
  onClose,
  onCreated,
}: {
  initial?: AdminCourse;
  onClose: () => void;
  onCreated: (id: string) => void;
}) {
  const { t } = useLang();
  const confirm = useConfirm();
  const toast = useToast();
  const qc = useQueryClient();
  const isEdit = !!initial;
  const coverRef = useRef<HTMLInputElement>(null);

  const [title, setTitle] = useState(initial?.title ?? "");
  const [description, setDescription] = useState(initial?.description ?? "");
  const [price, setPrice] = useState(initial?.price ? String(Number(initial.price)) : "0");
  const [level, setLevel] = useState(initial?.level ?? "beginner");
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);

  async function handleSubmit() {
    if (!title.trim()) return;
    const ok = await confirm({
      title: isEdit
        ? t.modal.updateTitle("kurs")
        : t.modal.createTitle("kurs"),
      description: isEdit
        ? t.modal.updateDesc("Kurs")
        : t.modal.createDesc("Kurs"),
      variant: "primary",
      confirmText: isEdit ? t.modal.save : t.modal.create,
    });
    if (!ok) return;

    setSaving(true);
    try {
      if (isEdit) {
        await api.patch(`/admin/courses/${initial.id}`, {
          title: title.trim(),
          description: description.trim() || null,
          price: parseFloat(price) || 0,
          level,
        });
        if (coverFile) {
          const fd = new FormData();
          fd.append("file", coverFile);
          await api.post(`/admin/courses/${initial.id}/cover`, fd, {
            headers: { "Content-Type": "multipart/form-data" },
          });
        }
        toast.success(t.videoLessons.updateSuccess);
        onCreated(initial.id);
      } else {
        const { data } = await api.post("/admin/courses", {
          title: title.trim(),
          description: description.trim() || null,
          price: parseFloat(price) || 0,
          level,
        });
        if (coverFile) {
          const fd = new FormData();
          fd.append("file", coverFile);
          await api.post(`/admin/courses/${data.id}/cover`, fd, {
            headers: { "Content-Type": "multipart/form-data" },
          });
        }
        toast.success(t.videoLessons.createSuccess);
        onCreated(data.id);
      }
      qc.invalidateQueries({ queryKey: ["admin", "courses"] });
    } catch (e) {
      toast.error(apiError(e));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal open onClose={onClose} size="lg">
      <ModalHeader
        title={isEdit ? "Kursni tahrirlash" : "Yangi kurs"}
        onClose={onClose}
      />
      <ModalBody>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleSubmit();
          }}
          className="grid gap-4 sm:grid-cols-2"
        >
          <label className="flex flex-col gap-1 sm:col-span-2">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Kurs nomi
            </span>
            <GlassInput
              required
              placeholder="Masalan: Nutq san'ati"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </label>
          <label className="flex flex-col gap-1 sm:col-span-2">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Tavsif
            </span>
            <GlassTextarea
              placeholder="Kurs haqida qisqacha..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Narxi (so'm)
            </span>
            <GlassInput
              type="number"
              min="0"
              placeholder="0"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
            />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Daraja
            </span>
            <GlassSelect
              value={level}
              onChange={(e) => setLevel(e.target.value)}
            >
              <option value="beginner">Boshlang'ich</option>
              <option value="intermediate">O'rta</option>
              <option value="advanced">Yuqori</option>
            </GlassSelect>
          </label>
          <div className="sm:col-span-2">
            <span className="text-xs font-bold uppercase tracking-wide text-muted">
              Muqova
            </span>
            <button
              type="button"
              onClick={() => coverRef.current?.click()}
              className="press mt-1 flex w-full items-center gap-2 rounded-xl border border-line bg-card px-4 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
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
        </form>
      </ModalBody>
      <ModalFooter>
        <ModalCancelButton onClick={onClose}>{t.common.cancel}</ModalCancelButton>
        <ModalSubmitButton
          onClick={handleSubmit}
          loading={saving}
          disabled={!title.trim()}
        >
          {isEdit ? t.common.save : t.modal.create}
        </ModalSubmitButton>
      </ModalFooter>
    </Modal>
  );
}
