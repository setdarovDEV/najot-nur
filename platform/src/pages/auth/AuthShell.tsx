import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { AmbientOrbs } from "../../components/glass";
import { useLang } from "../../lib/i18n";

export function AuthShell({
  children,
  subtitle,
}: {
  children: ReactNode;
  subtitle?: string;
}) {
  const { t } = useLang();
  return (
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-wine-deep via-wine-dark to-wine">
      <AmbientOrbs />
      <div
        className="pointer-events-none absolute -right-24 -top-24 h-[420px] w-[420px] rounded-full opacity-40"
        style={{
          background: "radial-gradient(circle, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0) 70%)",
        }}
      />
      <div className="relative mx-auto flex min-h-screen w-full max-w-md flex-col items-center justify-center px-5 py-10">
        <Link to="/login" className="mb-8 flex items-center gap-3">
          <img
            src="/logo.png"
            alt="NotiqAI"
            className="h-14 w-14 rounded-2xl object-cover shadow-2xl ring-4 ring-white/20"
          />
          <div className="text-white">
            <div className="text-xl font-black leading-none tracking-tight">
              {t.app.name}
            </div>
            <div className="mt-1.5 text-[11px] font-semibold uppercase tracking-widest text-white/60">
              {t.app.tagline}
            </div>
          </div>
        </Link>

        <div className="w-full rounded-[28px] border border-white/15 bg-white/90 p-6 shadow-2xl backdrop-blur-xl sm:p-8 dark:bg-[#251d20]/90">
          <div className="mb-5">
            <h1 className="text-xl font-extrabold text-ink">{t.auth.welcome}</h1>
            <p className="mt-1 text-xs leading-relaxed text-muted sm:text-sm">
              {subtitle ?? t.auth.subtitle}
            </p>
          </div>
          {children}
        </div>

        <p className="mt-6 text-center text-[11px] leading-relaxed text-white/50">
          {t.app.name} — {t.app.tagline}
        </p>
      </div>
    </div>
  );
}
