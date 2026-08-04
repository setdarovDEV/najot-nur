import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassInput, GlassCard, Spinner } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import { QuizCard } from "../../components/cards";
import type { Quiz } from "../../lib/types";
import { useState } from "react";

export function QuizzesPage() {
  const { t } = useLang();
  const [search, setSearch] = useState("");

  const quizzesQ = useQuery({
    queryKey: ["quizzes"],
    queryFn: async () => (await api.get<Quiz[]>("/quizzes")).data,
  });

  const quizzes = (quizzesQ.data ?? []).filter((q) =>
    q.title.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <PageHeader title={t.quizzes.title} subtitle={t.quizzes.subtitle} />
      <div className="relative mb-4 max-w-md">
        <Search size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
        <GlassInput
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t.common.search}
          className="pl-10"
        />
      </div>

      {quizzesQ.isLoading ? (
        <div className="py-16"><Spinner size={24} /></div>
      ) : quizzes.length === 0 ? (
        <GlassCard className="p-10 text-center text-sm text-muted">{t.quizzes.noQuizzes}</GlassCard>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {quizzes.map((q) => (
            <QuizCard key={q.id} quiz={q} />
          ))}
        </div>
      )}
    </div>
  );
}
