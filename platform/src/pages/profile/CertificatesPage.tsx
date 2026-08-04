import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Award, Download, FileText } from "lucide-react";
import { api, apiError, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, GlassInput, PrimaryButton, SecondaryButton, Spinner, StatusPill } from "../../components/glass";
import { Modal } from "../../components/Modal";
import type { Certificate, CertificateRequest, Enrollment } from "../../lib/types";

export function CertificatesPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [modalOpen, setModalOpen] = useState(false);
  const [courseId, setCourseId] = useState("");
  const [fullName, setFullName] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const certsQ = useQuery({
    queryKey: ["my-certificates"],
    queryFn: async () => (await api.get<Certificate[]>("/users/me/certificates")).data,
  });
  const requestsQ = useQuery({
    queryKey: ["certificate-requests"],
    queryFn: async () => (await api.get<CertificateRequest[]>("/certificates/my-requests")).data,
  });
  const enrollmentsQ = useQuery({
    queryKey: ["enrollments"],
    queryFn: async () => (await api.get<Enrollment[]>("/courses/me/enrollments")).data,
  });

  const completedCourses = (enrollmentsQ.data ?? []).filter(
    (e) => e.status === "completed" || e.status === "active",
  );

  async function submit() {
    if (!courseId || fullName.trim().length < 2) return;
    setSubmitting(true);
    try {
      await api.post("/certificates/request", {
        course_id: courseId,
        full_name: fullName.trim(),
      });
      toast.success(t.certificates.submit);
      setModalOpen(false);
      setCourseId("");
      setFullName("");
      requestsQ.refetch();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  const certificates = certsQ.data ?? [];
  const requests = requestsQ.data ?? [];

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-ink">{t.certificates.title}</h1>
          <p className="mt-1 text-xs text-muted sm:text-sm">{t.certificates.subtitle}</p>
        </div>
        {completedCourses.length > 0 && (
          <PrimaryButton onClick={() => setModalOpen(true)}>
            <Award size={15} /> {t.certificates.requestBtn}
          </PrimaryButton>
        )}
      </div>

      {certsQ.isLoading ? (
        <div className="py-12"><Spinner /></div>
      ) : certificates.length === 0 ? (
        <GlassCard className="p-10 text-center">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
            <Award size={26} />
          </div>
          <p className="mt-3 text-sm text-muted">{t.certificates.noCertificates}</p>
          <p className="mt-1 text-xs text-muted">{t.certificates.requestHint}</p>
        </GlassCard>
      ) : (
        <div className="space-y-2">
          {certificates.map((c) => (
            <GlassCard key={c.id} className="flex items-center gap-4 p-4">
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                <Award size={20} />
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-extrabold text-ink">{c.course_title}</div>
                <div className="mt-0.5 text-[11px] text-muted">
                  {t.certificates.issuedAt}: {new Date(c.issued_at).toLocaleDateString()}
                </div>
              </div>
              {c.pdf_url ? (
                <a
                  href={mediaUrl(c.pdf_url)!}
                  target="_blank"
                  rel="noreferrer"
                  className="press flex shrink-0 items-center gap-1.5 rounded-full border border-line px-3.5 py-2 text-xs font-bold text-ink transition hover:border-wine/40"
                >
                  <Download size={13} /> PDF
                </a>
              ) : (
                <span className="text-xs text-muted">—</span>
              )}
            </GlassCard>
          ))}
        </div>
      )}

      {requests.length > 0 && (
        <>
          <h2 className="mb-3 mt-8 text-sm font-extrabold uppercase tracking-wide text-muted">
            {t.certificates.requestTitle}
          </h2>
          <div className="space-y-2">
            {requests.map((r) => (
              <GlassCard key={r.id} className="flex items-center gap-4 p-4">
                <div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                  <FileText size={20} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-extrabold text-ink">{r.course_title}</div>
                  <div className="mt-0.5 text-[11px] text-muted">
                    {r.full_name} · {new Date(r.created_at).toLocaleDateString()}
                  </div>
                </div>
                <StatusPill
                  tone={r.status === "approved" ? "success" : r.status === "rejected" ? "danger" : "warning"}
                >
                  {r.status}
                </StatusPill>
              </GlassCard>
            ))}
          </div>
        </>
      )}

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={t.certificates.requestTitle}
        subtitle={t.certificates.requestHint}
      >
        <div className="space-y-4">
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.certificates.selectCourse}
            </label>
            <select
              value={courseId}
              onChange={(e) => setCourseId(e.target.value)}
              className="glass-input w-full px-3.5 py-2.5 text-sm text-ink"
            >
              <option value="">—</option>
              {completedCourses.map((e) => (
                <option key={e.course_id} value={e.course_id}>
                  {e.course_id.slice(0, 8)}…
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.certificates.fullName}
            </label>
            <GlassInput value={fullName} onChange={(e) => setFullName(e.target.value)} />
          </div>
          <div className="flex justify-end gap-2">
            <SecondaryButton onClick={() => setModalOpen(false)}>{t.common.cancel}</SecondaryButton>
            <PrimaryButton onClick={submit} loading={submitting} disabled={!courseId || fullName.trim().length < 2}>
              {t.certificates.submit}
            </PrimaryButton>
          </div>
        </div>
      </Modal>
    </div>
  );
}
