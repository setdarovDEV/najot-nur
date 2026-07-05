import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, apiError } from "../lib/api";
import type { Homework } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";

export function HomeworksPage() {
  const qc = useQueryClient();
  const { t } = useLang();
  const toast = useToast();
  const [filter, setFilter] = useState<"submitted" | "reviewed" | "">("submitted");

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
                    : "border border-line bg-card text-ink hover:bg-wine-50 dark:hover:bg-wine-900/20"
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

      <div className="space-y-4">
        {data?.map((hw) => (
          <HomeworkCard
            key={hw.id}
            hw={hw}
            onGrade={(score, feedback) =>
              grade.mutateAsync({ id: hw.id, score, feedback })
            }
          />
        ))}
      </div>
      {grade.isError && (
        <p className="mt-3 text-sm text-red-500 dark:text-red-400">{apiError(grade.error)}</p>
      )}
    </div>
  );
}

function HomeworkCard({
  hw,
  onGrade,
}: {
  hw: Homework;
  onGrade: (score: number, feedback: string) => Promise<unknown>;
}) {
  const { t } = useLang();
  const [score, setScore] = useState(hw.curator_score ?? 80);
  const [feedback, setFeedback] = useState(hw.curator_feedback ?? "");
  const [saving, setSaving] = useState(false);

  return (
    <div className="rounded-2xl border border-line bg-card p-5">
      <div className="mb-3 flex items-center justify-between">
        <span className="text-xs text-muted">
          {new Date(hw.created_at).toLocaleString()}
        </span>
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
      <p className="mb-4 text-sm text-ink">
        {hw.submission_text ?? hw.submission_url ?? "—"}
      </p>

      <div className="flex flex-wrap items-end gap-3">
        <label className="text-sm">
          <span className="mb-1 block font-semibold text-ink">{t.homeworks.score} (0-100)</span>
          <input
            type="number"
            min={0}
            max={100}
            value={score}
            onChange={(e) => setScore(Number(e.target.value))}
            className="w-24 rounded-lg border border-line bg-card px-3 py-2 text-ink outline-none focus:border-wine dark:bg-[#251d20]"
          />
        </label>
        <label className="flex-1 text-sm">
          <span className="mb-1 block font-semibold text-ink">{t.homeworks.feedback}</span>
          <input
            value={feedback}
            onChange={(e) => setFeedback(e.target.value)}
            placeholder="..."
            className="w-full rounded-lg border border-line bg-card px-3 py-2 text-ink placeholder:text-muted outline-none focus:border-wine dark:bg-[#251d20]"
          />
        </label>
        <button
          disabled={saving}
          onClick={async () => {
            setSaving(true);
            try {
              await onGrade(score, feedback);
            } finally {
              setSaving(false);
            }
          }}
          className="rounded-lg bg-wine px-5 py-2.5 text-sm font-bold text-white hover:bg-wine-dark disabled:opacity-60"
        >
          {saving ? t.common.saving : t.homeworks.grade}
        </button>
      </div>
    </div>
  );
}
