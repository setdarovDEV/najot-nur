import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { api } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassInput, GlassCard, Spinner } from "../../components/glass";
import { PageHeader } from "../../components/Layout";
import { CourseCard } from "../../components/cards";
import type { Course } from "../../lib/types";
import { useState } from "react";

export function CoursesPage() {
  const { t } = useLang();
  const [search, setSearch] = useState("");

  const coursesQ = useQuery({
    queryKey: ["courses"],
    queryFn: async () => (await api.get<Course[]>("/courses")).data,
  });

  const courses = (coursesQ.data ?? []).filter((c) =>
    c.title.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <PageHeader title={t.courses.title} subtitle={t.courses.subtitle} />
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

      {coursesQ.isLoading ? (
        <div className="py-16"><Spinner size={24} /></div>
      ) : courses.length === 0 ? (
        <GlassCard className="p-10 text-center text-sm text-muted">{t.common.noData}</GlassCard>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {courses.map((c) => (
            <CourseCard key={c.id} course={c} />
          ))}
        </div>
      )}
    </div>
  );
}
