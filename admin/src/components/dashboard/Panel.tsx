import type { ReactNode } from "react";

export function Panel({
  title,
  subtitle,
  icon,
  action,
  children,
  className = "",
  padding = "p-5",
}: {
  title: string;
  subtitle?: string;
  icon?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  padding?: string;
}) {
  return (
    <section
      className={`rounded-2xl border border-line bg-card ${padding} ${className}`}
    >
      <header className="mb-3 flex items-start justify-between gap-3 sm:mb-4">
        <div className="flex items-start gap-2.5 sm:gap-3">
          {icon && (
            <div className="grid h-8 w-8 shrink-0 place-items-center rounded-xl bg-wine/10 text-wine dark:bg-wine/15 dark:text-wine-300 sm:h-9 sm:w-9">
              {icon}
            </div>
          )}
          <div>
            <h3 className="text-sm font-extrabold text-ink sm:text-base">{title}</h3>
            {subtitle && (
              <p className="mt-0.5 text-xs text-muted">{subtitle}</p>
            )}
          </div>
        </div>
        {action}
      </header>
      {children}
    </section>
  );
}
