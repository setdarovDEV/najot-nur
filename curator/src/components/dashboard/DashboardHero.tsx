import { useLang } from "../../lib/i18n";

export function DashboardHero({
  fullName,
  statusLabel,
  statusTone = "green",
}: {
  fullName: string | null;
  statusLabel: string;
  statusTone?: "green" | "amber" | "red";
}) {
  const { t, lang } = useLang();
  const greeting = pickGreeting(t.dashboard.greeting);
  const firstName = (fullName ?? "").split(" ")[0] || "Kurator";

  const locales: Record<string, string> = { uz: "uz-UZ", ru: "ru-RU", en: "en-US" };
  const today = new Intl.DateTimeFormat(locales[lang] ?? "uz-UZ", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date());

  const tone: Record<string, string> = {
    green: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
    amber: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
    red: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  };

  return (
    <section className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-wine via-wine-dark to-wine-deep p-6 text-white shadow-xl shadow-wine-deep/20 md:p-8">
      <div className="pointer-events-none absolute -right-12 -top-12 h-56 w-56 rounded-full bg-white/5 blur-2xl" />
      <div className="pointer-events-none absolute -bottom-16 -left-10 h-48 w-48 rounded-full bg-orange/20 blur-3xl" />

      <div className="relative flex flex-col gap-5 md:flex-row md:items-center md:justify-between">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-white/70">
            <span className="inline-block h-1.5 w-1.5 rounded-full bg-orange" />
            {today}
          </div>
          <h1 className="mt-2 text-2xl font-extrabold leading-tight md:text-3xl">
            {greeting}, {firstName}! 👋
          </h1>
          <p className="mt-2 max-w-xl text-sm leading-relaxed text-white/80">
            {t.dashboard.curatorDesc}
          </p>
        </div>

        <div className="flex flex-col items-start gap-3 md:items-end">
          <span
            className={`inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-xs font-bold ${tone[statusTone]}`}
          >
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-current opacity-60" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-current" />
            </span>
            {statusLabel}
          </span>
          <div className="text-xs text-white/70">
            <span className="font-bold text-white">NotiqAI</span> · Najot Nur
          </div>
        </div>
      </div>
    </section>
  );
}

function pickGreeting(g: { night: string; morning: string; day: string; evening: string }): string {
  const h = new Date().getHours();
  if (h < 6) return g.night;
  if (h < 12) return g.morning;
  if (h < 18) return g.day;
  return g.evening;
}
