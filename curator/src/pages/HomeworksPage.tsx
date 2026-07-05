import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Headphones, FileText, ExternalLink, Mic } from "lucide-react";
import { api, apiError, mediaUrl } from "../lib/api";
import type { Homework } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { Modal, ModalBody, ModalFooter, ModalHeader } from "../components/Modal";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";

export function HomeworksPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const [filter, setFilter] = useState<"submitted" | "reviewed" | "">("submitted");
  const [openHw, setOpenHw] = useState<Homework | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["homeworks", filter],
    queryFn: async () =>
      (
        await api.get<Homework[]>("/admin/homeworks", {
          params: { status: filter || undefined },
        })
      ).data,
  });

  const grade = useMutation({
    mutationFn: (vars: { id: string; score: number; feedback: string }) =>
      api.post(`/admin/homeworks/${vars.id}/grade`, {
        score: vars.score,
        feedback: vars.feedback,
      }),
    onSuccess: () => {
      toast.success(t.homeworks.gradeSuccess);
      qc.invalidateQueries({ queryKey: ["homeworks"] });
      setOpenHw(null);
    },
    onError: (e) => toast.error(apiError(e)),
  });

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={t.homeworks.title}
        subtitle={t.homeworks.subtitle}
        actions={
          <>
            {(["submitted", "reviewed", ""] as const).map((f) => (
              <button
                key={f || "all"}
                onClick={() => setFilter(f)}
                className={`rounded-lg px-4 py-2 text-sm font-semibold ${
                  filter === f
                    ? "bg-wine text-white"
                    : "border border-line bg-card text-ink hover:bg-wine-50"
                }`}
              >
                {f === "submitted"
                  ? t.homeworks.new_
                  : f === "reviewed"
                    ? t.homeworks.reviewed
                    : t.homeworks.all}
              </button>
            ))}
          </>
        }
      />

      {isLoading && <p className="text-muted">{t.common.loading}</p>}
      {data && data.length === 0 && (
        <p className="rounded-xl border border-line bg-card p-6 text-muted">
          {t.homeworks.noHomeworks}
        </p>
      )}

      <div className="space-y-3">
        {data?.map((hw) => (
          <HomeworkCard key={hw.id} hw={hw} onOpen={() => setOpenHw(hw)} />
        ))}
      </div>

      {openHw && (
        <HomeworkDetailModal
          hw={openHw}
          saving={grade.isPending}
          error={grade.isError ? apiError(grade.error) : null}
          onClose={() => setOpenHw(null)}
          onGrade={async (score, feedback) => {
            await grade.mutateAsync({ id: openHw.id, score, feedback });
          }}
        />
      )}

      {grade.isError && !openHw && (
        <p className="mt-3 text-sm text-red-500">{apiError(grade.error)}</p>
      )}
    </div>
  );
}

function HomeworkCard({
  hw,
  onOpen,
}: {
  hw: Homework;
  onOpen: () => void;
}) {
  const { t } = useLang();
  const hasText = !!hw.submission_text;
  const hasAudio = !!hw.submission_url;
  const displayName =
    hw.user_full_name || hw.user_phone || hw.user_id.slice(0, 8);

  return (
    <button
      type="button"
      onClick={onOpen}
      className="w-full rounded-2xl border border-line bg-card p-5 text-left transition hover:border-wine hover:shadow-md"
    >
      <div className="mb-3 flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm font-semibold text-ink">
          <span>{displayName}</span>
          {hw.lesson_title && (
            <span className="rounded-md bg-surface px-2 py-0.5 text-xs font-medium text-muted">
              {hw.lesson_title}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          {hasText && (
            <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
              <FileText size={12} /> {t.homeworks.hasText}
            </span>
          )}
          {hasAudio && (
            <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2 py-0.5 text-xs font-semibold text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
              <Mic size={12} /> {t.homeworks.hasAudio}
            </span>
          )}
          <span
            className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
              hw.status === "reviewed"
                ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
            }`}
          >
            {hw.status === "reviewed" ? t.homeworks.reviewed : t.homeworks.new_}
          </span>
        </div>
      </div>
      <p className="line-clamp-2 text-sm text-muted">
        {hw.submission_text ?? "—"}
      </p>
      <div className="mt-3 flex items-center justify-between text-xs text-muted">
        <span>{new Date(hw.created_at).toLocaleString()}</span>
        <span className="inline-flex items-center gap-1 text-wine">
          <ExternalLink size={12} /> {t.homeworks.openDetails}
        </span>
      </div>
    </button>
  );
}

function HomeworkDetailModal({
  hw,
  saving,
  error,
  onClose,
  onGrade,
}: {
  hw: Homework;
  saving: boolean;
  error: string | null;
  onClose: () => void;
  onGrade: (score: number, feedback: string) => Promise<unknown>;
}) {
  const { t } = useLang();
  const [score, setScore] = useState(hw.curator_score ?? 80);
  const [feedback, setFeedback] = useState(hw.curator_feedback ?? "");

  const audioSrc = mediaUrl(hw.submission_url);
  const isAudioPlayable = audioSrc !== null;

  const displayName =
    hw.user_full_name || hw.user_phone || hw.user_id.slice(0, 8);

  return (
    <Modal open onClose={onClose} size="lg">
      <ModalHeader title={displayName} onClose={onClose} />
      <ModalBody>
        <div className="space-y-4">
          {/* Meta: lesson + timestamp */}
          <div className="flex flex-wrap items-center gap-2 text-sm text-muted">
            {hw.lesson_title && (
              <span className="rounded-md bg-surface px-2 py-1 text-xs font-medium">
                {t.homeworks.lesson}: {hw.lesson_title}
              </span>
            )}
            <span className="rounded-md bg-surface px-2 py-1 text-xs font-medium">
              {t.homeworks.submittedAt}: {new Date(hw.created_at).toLocaleString()}
            </span>
            {hw.user_phone && (
              <span className="rounded-md bg-surface px-2 py-1 text-xs font-medium">
                {hw.user_phone}
              </span>
            )}
          </div>

          {/* Text answer */}
          <div>
            <h3 className="mb-2 inline-flex items-center gap-1 text-sm font-bold text-ink">
              <FileText size={14} /> {t.homeworks.textAnswer}
            </h3>
            {hw.submission_text ? (
              <div className="max-h-64 overflow-y-auto rounded-xl border border-line bg-surface p-4 text-sm leading-relaxed text-ink">
                {hw.submission_text}
              </div>
            ) : (
              <p className="rounded-xl border border-dashed border-line bg-surface p-4 text-sm text-muted">
                {t.homeworks.noTextAnswer}
              </p>
            )}
          </div>

          {/* Voice answer */}
          <div>
            <h3 className="mb-2 inline-flex items-center gap-1 text-sm font-bold text-ink">
              <Headphones size={14} /> {t.homeworks.voiceAnswer}
            </h3>
            {isAudioPlayable ? (
              <div className="rounded-xl border border-line bg-surface p-3">
                <audio
                  src={audioSrc ?? undefined}
                  controls
                  className="w-full"
                  preload="metadata"
                />
              </div>
            ) : (
              <p className="rounded-xl border border-dashed border-line bg-surface p-4 text-sm text-muted">
                {t.homeworks.noVoiceAnswer}
              </p>
            )}
          </div>

          {/* Grade form */}
          <div className="border-t border-line pt-4">
            <h3 className="mb-3 text-sm font-bold text-ink">{t.homeworks.grade}</h3>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-[120px_1fr]">
              <label className="text-sm">
                <span className="mb-1 block font-semibold text-ink">
                  {t.homeworks.score} (0-100)
                </span>
                <input
                  type="number"
                  min={0}
                  max={100}
                  value={score}
                  onChange={(e) => setScore(Number(e.target.value))}
                  className="w-full rounded-lg border border-line bg-card px-3 py-2 text-ink outline-none focus:border-wine dark:bg-[#251d20]"
                />
              </label>
              <label className="text-sm">
                <span className="mb-1 block font-semibold text-ink">
                  {t.homeworks.feedback}
                </span>
                <textarea
                  value={feedback}
                  onChange={(e) => setFeedback(e.target.value)}
                  rows={3}
                  placeholder="..."
                  className="w-full rounded-lg border border-line bg-card px-3 py-2 text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
                />
              </label>
            </div>
            {error && <p className="mt-2 text-sm text-red-500">{error}</p>}
          </div>
        </div>
      </ModalBody>
      <ModalFooter>
        <button
          type="button"
          onClick={onClose}
          className="rounded-xl border border-line px-5 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
        >
          {t.common.cancel}
        </button>
        <button
          type="button"
          disabled={saving}
          onClick={() => void onGrade(score, feedback)}
          className="flex items-center gap-2 rounded-xl bg-wine px-5 py-2.5 text-sm font-bold text-white transition hover:bg-wine-dark disabled:opacity-60"
        >
          {saving && (
            <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent" />
          )}
          {saving ? t.homeworks.grading : t.homeworks.submitGrade}
        </button>
      </ModalFooter>
    </Modal>
  );
}
