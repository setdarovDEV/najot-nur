import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassInput, GlassCard, Spinner } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import { PracticumCard } from "../../components/cards";
import type { Practicum } from "../../lib/types";
import { useState } from "react";

export function PracticumsPage() {
  const { t } = useLang();
  const [search, setSearch] = useState("");

  const practicumsQ = useQuery({
    queryKey: ["practicums"],
    queryFn: async () => (await api.get<Practicum[]>("/practicums")).data,
  });

  const practicums = (practicumsQ.data ?? []).filter((p) =>
    p.title.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <PageHeader title={t.practicums.title} subtitle={t.practicums.subtitle} />
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

      {practicumsQ.isLoading ? (
        <div className="py-16"><Spinner size={24} /></div>
      ) : practicums.length === 0 ? (
        <GlassCard className="p-10 text-center text-sm text-muted">{t.common.noData}</GlassCard>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {practicums.map((p) => (
            <PracticumCard key={p.id} practicum={p} />
          ))}
        </div>
      )}
    </div>
  );
}
