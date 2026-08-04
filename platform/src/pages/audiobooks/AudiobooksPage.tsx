import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassInput, GlassCard, Spinner } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import { SegmentedControl } from "../../components/glass";
import { AudiobookCard } from "../../components/cards";
import type { Audiobook } from "../../lib/types";

type Filter = "all" | "free";

export function AudiobooksPage() {
  const { t } = useLang();
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<Filter>("all");

  const booksQ = useQuery({
    queryKey: ["audiobooks"],
    queryFn: async () => (await api.get<Audiobook[]>("/audiobooks")).data,
  });

  const books = (booksQ.data ?? []).filter((b) => {
    const matchesSearch = b.title.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = filter === "all" || b.is_free;
    return matchesSearch && matchesFilter;
  });

  return (
    <div>
      <PageHeader title={t.audiobooks.title} subtitle={t.audiobooks.subtitle} />
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative max-w-md flex-1">
          <Search size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
          <GlassInput
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t.common.search}
            className="pl-10"
          />
        </div>
        <SegmentedControl
          options={[
            { value: "all" as Filter, label: t.common.all },
            { value: "free" as Filter, label: t.common.free },
          ]}
          value={filter}
          onChange={setFilter}
        />
      </div>

      {booksQ.isLoading ? (
        <div className="py-16"><Spinner size={24} /></div>
      ) : books.length === 0 ? (
        <GlassCard className="p-10 text-center text-sm text-muted">{t.common.noData}</GlassCard>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {books.map((b) => (
            <AudiobookCard key={b.id} book={b} />
          ))}
        </div>
      )}
    </div>
  );
}
