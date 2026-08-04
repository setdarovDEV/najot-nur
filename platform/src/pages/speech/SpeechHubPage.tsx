import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { AudioLines, BookOpenText, Mic, ArrowRight } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, Reveal } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import type { SpeechAnalysis } from "../../lib/types";

export function SpeechHubPage() {
  const { t } = useLang();

  const historyQ = useQuery({
    queryKey: ["speech-history"],
    queryFn: async () => (await api.get<SpeechAnalysis[]>("/speech/history")).data,
  });

  const features = [
    {
      to: "/speech/talk",
      icon: Mic,
      title: t.home.freeTalk,
      desc: t.speech.talkDescription,
    },
    {
      to: "/speech/voice",
      icon: AudioLines,
      title: t.home.voiceTest,
      desc: t.speech.voiceDescription,
    },
    {
      to: "/speech/practice",
      icon: BookOpenText,
      title: t.speech.practice,
      desc: t.speech.practiceDescription,
    },
  ];

  const recent = historyQ.data?.slice(0, 5) ?? [];

  return (
    <div>
      <PageHeader title={t.speech.title} subtitle={t.speech.subtitle} />

      <div className="grid gap-4 sm:grid-cols-3">
        {features.map((f, i) => (
          <Reveal key={f.to} index={i}>
            <Link to={f.to} className="block h-full">
              <GlassCard className="press flex h-full flex-col p-6 transition hover:-translate-y-0.5 hover:shadow-lg">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                  <f.icon size={24} />
                </div>
                <h3 className="mt-4 text-base font-extrabold text-ink">{f.title}</h3>
                <p className="mt-1.5 flex-1 text-xs leading-relaxed text-muted">{f.desc}</p>
                <span className="mt-4 flex items-center gap-1 text-xs font-bold text-wine">
                  {t.common.start} <ArrowRight size={13} />
                </span>
              </GlassCard>
            </Link>
          </Reveal>
        ))}
      </div>

      <h2 className="mb-3 mt-8 text-sm font-extrabold uppercase tracking-wide text-muted">
        {t.history.speech}
      </h2>
      {historyQ.isLoading ? null : recent.length === 0 ? (
        <GlassCard className="p-6 text-center text-sm text-muted">{t.history.noData}</GlassCard>
      ) : (
        <div className="space-y-2">
          {recent.map((a) => (
            <Link key={a.id} to={`/profile/history`}>
              <GlassCard className="press flex items-center gap-4 p-4 transition hover:shadow-md">
                <div className="grid h-10 w-10 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                  <Mic size={18} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-extrabold text-ink">
                    {a.transcript ?? "—"}
                  </div>
                  <div className="mt-0.5 text-[11px] text-muted">
                    {new Date(a.created_at).toLocaleString()}
                  </div>
                </div>
                {a.overall_score != null && (
                  <span className="text-sm font-black text-wine">{a.overall_score}</span>
                )}
              </GlassCard>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
