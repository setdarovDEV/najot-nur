import { useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import type { ReactNode } from "react";
import {
  LayoutDashboard,
  ClipboardList,
  Headphones,
  LogOut,
  Video,
  ShieldCheck,
  Search,
  ChevronDown,
  MessageCircle,
  Sun,
  Moon,
  Globe,
  Mic,
  Award,
  BookOpen,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { useTheme } from "../lib/theme";
import { useLang, LANG_LABELS, LANG_NAMES, type Lang } from "../lib/i18n";

interface NavItem {
  to: string;
  labelKey: keyof ReturnType<typeof useLang>["t"]["nav"];
  icon: LucideIcon;
  end?: boolean;
  readOnly?: boolean;
}

const CURATOR_NAV: NavItem[] = [
  { to: "/", labelKey: "dashboard", icon: LayoutDashboard, end: true },
  { to: "/homeworks", labelKey: "homeworks", icon: ClipboardList },
  { to: "/certificate-requests", labelKey: "certificateRequests", icon: Award },
  { to: "/references", labelKey: "references", icon: Mic },
  { to: "/practicums", labelKey: "practicums", icon: Headphones },
  { to: "/quizzes", labelKey: "quizzes", icon: BookOpen },
  { to: "/audiobooks", labelKey: "audiobooks", icon: Headphones },
  { to: "/video-lessons", labelKey: "videoLessons", icon: Video },
  { to: "/support-chats", labelKey: "supportChats", icon: MessageCircle },
];

export function Layout() {
  const { logout, user } = useAuth();
  const navigate = useNavigate();
  const { theme, toggle: toggleTheme } = useTheme();
  const { lang, setLang, t } = useLang();
  const [menuOpen, setMenuOpen] = useState(false);
  const [langOpen, setLangOpen] = useState(false);

  const fullName = user?.full_name ?? "Kurator";
  const email = user?.email ?? "curator@najotnur.uz";

  return (
    <div className="flex min-h-screen bg-surface">
      <aside className="sticky top-0 hidden h-screen w-72 shrink-0 flex-col overflow-y-auto bg-gradient-to-b from-wine via-wine-dark to-wine-deep p-5 text-white md:flex">
        <div className="mb-8 flex items-center gap-3">
          <div className="grid h-12 w-12 place-items-center rounded-2xl bg-white/15 text-lg font-black shadow-inner">
            NN
          </div>
          <div>
            <div className="text-lg font-extrabold leading-none tracking-tight">
              NotiqAI
            </div>
            <div className="mt-1 flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wider text-white/70">
              <ShieldCheck size={11} />
              {t.sidebar.curatorPanel}
            </div>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1">
          {CURATOR_NAV.map((n) => (
            <NavLink
              key={n.to}
              to={n.to}
              end={n.end}
              title={t.nav[n.labelKey]}
              className={({ isActive }) =>
                `group flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition ${
                  isActive
                    ? "bg-white text-wine-dark shadow-lg shadow-wine-deep/30"
                    : "text-white/85 hover:bg-white/10"
                }`
              }
            >
              <n.icon size={19} strokeWidth={1.75} className="shrink-0" />
              <span className="min-w-0 flex-1 truncate">{t.nav[n.labelKey]}</span>
              {n.readOnly && (
                <span className="shrink-0 rounded-full bg-white/20 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">
                  view
                </span>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="mt-6 rounded-2xl border border-white/15 bg-white/5 p-4 text-xs text-white/80">
          <div className="mb-1 font-bold text-white">Najot Nur</div>
          <p className="leading-relaxed text-white/65">{t.sidebar.tagline}</p>
        </div>

        <button
          onClick={() => {
            logout();
            navigate("/login");
          }}
          className="mt-4 flex items-center gap-3 rounded-xl border border-white/25 px-4 py-3 text-sm font-semibold text-white/90 transition hover:bg-white/10"
        >
          <LogOut size={18} strokeWidth={1.75} />
          {t.sidebar.logout}
        </button>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-4 border-b border-line bg-card/80 px-5 backdrop-blur-md md:px-8">
          <div className="flex-1">
            <div className="relative max-w-md">
              <Search
                size={16}
                className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
              />
              <input
                type="text"
                placeholder={t.topbar.searchCurator}
                className="w-full rounded-xl border border-line bg-card py-2.5 pl-10 pr-4 text-sm text-ink placeholder:text-muted outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10 dark:bg-[#251d20]"
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={toggleTheme}
              title={theme === "dark" ? "Light mode" : "Dark mode"}
              className="grid h-9 w-9 place-items-center rounded-xl border border-line text-muted transition hover:border-wine/30 hover:text-wine dark:hover:text-white"
            >
              {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
            </button>

            <div className="relative">
              <button
                onClick={() => { setLangOpen((v) => !v); setMenuOpen(false); }}
                className="flex items-center gap-1.5 rounded-xl border border-line px-3 py-2 text-xs font-bold text-ink transition hover:border-wine/30 dark:hover:border-wine/50"
              >
                <Globe size={13} className="text-muted" />
                {LANG_LABELS[lang]}
                <ChevronDown size={12} className={`text-muted transition ${langOpen ? "rotate-180" : ""}`} />
              </button>
              {langOpen && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setLangOpen(false)} />
                  <div className="absolute right-0 z-20 mt-2 w-36 overflow-hidden rounded-2xl border border-line bg-card shadow-xl">
                    {(["uz", "ru", "en"] as Lang[]).map((l) => (
                      <button
                        key={l}
                        onClick={() => { setLang(l); setLangOpen(false); }}
                        className={`flex w-full items-center gap-2 px-4 py-2.5 text-sm font-semibold transition hover:bg-wine-50 ${
                          lang === l ? "text-wine" : "text-ink"
                        }`}
                      >
                        <span className="w-7 text-xs font-black">{LANG_LABELS[l]}</span>
                        {LANG_NAMES[l]}
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>

            <span className="hidden rounded-full bg-wine/15 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-wine sm:inline-flex">
              {t.topbar.curator}
            </span>

            <div className="relative">
              <button
                onClick={() => { setMenuOpen((v) => !v); setLangOpen(false); }}
                className="flex items-center gap-2.5 rounded-xl border border-line bg-card py-1.5 pl-1.5 pr-3 text-left transition hover:border-wine/30"
              >
                <div className="grid h-8 w-8 place-items-center rounded-lg bg-wine text-xs font-black text-white">
                  KR
                </div>
                <div className="hidden sm:block">
                  <div className="text-sm font-bold leading-none text-ink">
                    {fullName}
                  </div>
                  <div className="mt-0.5 text-[11px] text-muted">{email}</div>
                </div>
                <ChevronDown
                  size={14}
                  className={`hidden text-muted transition sm:block ${
                    menuOpen ? "rotate-180" : ""
                  }`}
                />
              </button>

              {menuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-10"
                    onClick={() => setMenuOpen(false)}
                  />
                  <div className="absolute right-0 z-20 mt-2 w-56 overflow-hidden rounded-2xl border border-line bg-card shadow-xl">
                    <div className="border-b border-line bg-wine-50 px-4 py-3">
                      <div className="text-sm font-bold text-ink">
                        {fullName}
                      </div>
                      <div className="mt-0.5 text-xs text-muted">{email}</div>
                    </div>
                    <button
                      onClick={() => {
                        setMenuOpen(false);
                        logout();
                        navigate("/login");
                      }}
                      className="flex w-full items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50"
                    >
                      <LogOut size={15} className="text-wine" />
                      {t.topbar.signOut}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-x-hidden">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl font-extrabold text-ink">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-muted">{subtitle}</p>}
      </div>
      {actions}
    </div>
  );
}
