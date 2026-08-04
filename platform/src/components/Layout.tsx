import { useState } from "react";
import { NavLink, Outlet, useNavigate, useLocation } from "react-router-dom";
import type { ReactNode } from "react";
import {
  Home,
  BookOpen,
  Headphones,
  FileQuestion,
  User,
  Mic,
  Eye,
  Layers,
  LogOut,
  Sun,
  Moon,
  Globe,
  ChevronDown,
  MoreVertical,
  type LucideIcon,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { useTheme } from "../lib/theme";
import { useLang, LANG_LABELS, LANG_NAMES, type Lang } from "../lib/i18n";
import { AmbientOrbs } from "./glass";

interface NavItem {
  to: string;
  labelKey: keyof ReturnType<typeof useLang>["t"]["nav"];
  icon: LucideIcon;
  end?: boolean;
}

const PRIMARY_NAV: NavItem[] = [
  { to: "/", labelKey: "home", icon: Home, end: true },
  { to: "/courses", labelKey: "courses", icon: BookOpen },
  { to: "/audiobooks", labelKey: "audiobooks", icon: Headphones },
  { to: "/quizzes", labelKey: "quizzes", icon: FileQuestion },
  { to: "/profile", labelKey: "profile", icon: User },
];

const SECONDARY_NAV: NavItem[] = [
  { to: "/speech", labelKey: "speech", icon: Mic },
  { to: "/observation", labelKey: "observation", icon: Eye },
  { to: "/practicums", labelKey: "practicums", icon: Layers },
];

export function Layout() {
  const { logout, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { theme, toggle: toggleTheme } = useTheme();
  const { lang, setLang, t } = useLang();
  const [langOpen, setLangOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  const fullName = user?.full_name ?? "Foydalanuvchi";
  const phone = user?.phone ?? "";

  const inSpeechFlow =
    location.pathname.startsWith("/speech") || location.pathname.startsWith("/observation");

  const desktopNav = [...PRIMARY_NAV, ...SECONDARY_NAV];

  const renderNavLink = (n: NavItem) => (
    <NavLink
      key={n.to}
      to={n.to}
      end={n.end}
      className={({ isActive }) =>
        `press flex items-center gap-2 rounded-full px-3.5 py-2 text-sm font-semibold transition ${
          isActive
            ? "bg-white text-wine shadow-md shadow-wine-deep/20 dark:bg-white/10"
            : "text-ink/70 hover:bg-white/60 dark:text-white/75 dark:hover:bg-white/5"
        }`
      }
    >
      <n.icon size={17} strokeWidth={1.9} className="shrink-0" />
      <span className="whitespace-nowrap">{t.nav[n.labelKey]}</span>
    </NavLink>
  );

  return (
    <div className="relative min-h-screen pb-20 md:pb-0">
      <AmbientOrbs />

      {/* ── Desktop header ── */}
      <header className="glass-chrome sticky top-0 z-30 hidden border-b px-6 md:block">
        <div className="mx-auto flex h-16 max-w-6xl items-center gap-5">
          <NavLink to="/" className="flex shrink-0 items-center gap-3">
            <img src="/logo.png" alt="NotiqAI" className="h-9 w-9 rounded-xl object-cover" />
            <span className="text-base font-black tracking-tight text-ink">
              {t.app.name}
            </span>
          </NavLink>

          <nav className="flex flex-1 items-center gap-1 overflow-x-auto">{desktopNav.map(renderNavLink)}</nav>

          <div className="ml-auto flex shrink-0 items-center gap-2">
            {/* Theme */}
            <button
              onClick={toggleTheme}
              title={theme === "dark" ? "Light mode" : "Dark mode"}
              className="press grid h-9 w-9 place-items-center rounded-full border border-line text-muted transition hover:border-wine/30 hover:text-wine dark:hover:text-white"
            >
              {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
            </button>

            {/* Language */}
            <div className="relative">
              <button
                onClick={() => { setLangOpen((v) => !v); setMenuOpen(false); }}
                className="press flex items-center gap-1.5 rounded-full border border-line px-3 py-2 text-xs font-bold text-ink transition hover:border-wine/30"
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
                        className={`flex w-full items-center gap-2 px-4 py-2.5 text-sm font-semibold transition hover:bg-wine-50 dark:hover:bg-wine/10 ${
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

            {/* User menu */}
            <div className="relative">
              <button
                onClick={() => { setMenuOpen((v) => !v); setLangOpen(false); }}
                className="press flex items-center gap-2.5 rounded-full border border-line bg-card py-1.5 pl-1.5 pr-3 text-left transition hover:border-wine/30"
              >
                <div className="grid h-8 w-8 place-items-center rounded-full bg-wine text-xs font-black text-white">
                  {(fullName.match(/\b\w/g) ?? ["N"]).slice(0, 2).join("").toUpperCase()}
                </div>
                <span className="hidden max-w-[8rem] truncate text-sm font-bold text-ink sm:block">
                  {fullName}
                </span>
                <ChevronDown
                  size={14}
                  className={`hidden text-muted transition sm:block ${menuOpen ? "rotate-180" : ""}`}
                />
              </button>

              {menuOpen && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setMenuOpen(false)} />
                  <div className="absolute right-0 z-20 mt-2 w-56 overflow-hidden rounded-2xl border border-line bg-card shadow-xl">
                    <div className="border-b border-line bg-wine-50 px-4 py-3 dark:bg-wine/10">
                      <div className="text-sm font-bold text-ink">{fullName}</div>
                      {phone && <div className="mt-0.5 text-xs text-muted">{phone}</div>}
                    </div>
                    <button
                      onClick={() => { setMenuOpen(false); navigate("/profile"); }}
                      className="flex w-full items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
                    >
                      <User size={15} className="text-wine" />
                      {t.nav.profile}
                    </button>
                    <button
                      onClick={() => { setMenuOpen(false); logout(); navigate("/login"); }}
                      className="flex w-full items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
                    >
                      <LogOut size={15} className="text-wine" />
                      {t.profile.logout}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* ── Mobile top bar ── */}
      <header className="glass-chrome sticky top-0 z-30 flex h-14 items-center gap-3 border-b px-4 md:hidden">
        <NavLink to="/" className="flex items-center gap-2">
          <img src="/logo.png" alt="NotiqAI" className="h-8 w-8 rounded-lg object-cover" />
          <span className="text-sm font-black tracking-tight text-ink">{t.app.name}</span>
        </NavLink>
        <div className="ml-auto flex items-center gap-2">
          <button
            onClick={toggleTheme}
            title="Theme"
            className="press grid h-9 w-9 place-items-center rounded-full border border-line text-muted transition hover:text-wine"
          >
            {theme === "dark" ? <Sun size={15} /> : <Moon size={15} />}
          </button>
          <button
            onClick={() => { setMobileOpen((v) => !v); }}
            className="press grid h-9 w-9 place-items-center rounded-full border border-line text-muted transition hover:text-wine"
            aria-label="Menu"
          >
            <MoreVertical size={16} />
          </button>
        </div>

        {mobileOpen && (
          <div className="absolute right-4 top-14 z-30 w-56 overflow-hidden rounded-2xl border border-line bg-card shadow-xl">
            <NavLink
              to="/speech"
              onClick={() => setMobileOpen(false)}
              className="flex items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
            >
              <Mic size={15} className="text-wine" /> {t.nav.speech}
            </NavLink>
            <NavLink
              to="/observation"
              onClick={() => setMobileOpen(false)}
              className="flex items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
            >
              <Eye size={15} className="text-wine" /> {t.nav.observation}
            </NavLink>
            <NavLink
              to="/practicums"
              onClick={() => setMobileOpen(false)}
              className="flex items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
            >
              <Layers size={15} className="text-wine" /> {t.nav.practicums}
            </NavLink>
            <div className="border-t border-line" />
            <button
              onClick={() => { setMobileOpen(false); logout(); navigate("/login"); }}
              className="flex w-full items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
            >
              <LogOut size={15} className="text-wine" /> {t.profile.logout}
            </button>
          </div>
        )}
      </header>

      {/* ── Content ── */}
      <main
        className={`mx-auto w-full max-w-6xl px-4 py-4 sm:px-6 md:py-8 ${
          inSpeechFlow ? "max-w-4xl" : ""
        }`}
      >
        <Outlet />
      </main>

      {/* ── Mobile bottom nav ── */}
      <nav className="glass-chrome fixed inset-x-0 bottom-0 z-30 border-t px-2 py-1.5 md:hidden">
        <div className="mx-auto flex max-w-md items-center justify-around">
          {PRIMARY_NAV.map((n) => (
            <NavLink key={n.to} to={n.to} end={n.end}>
              {({ isActive }) => (
                <span
                  className={`press flex flex-col items-center gap-0.5 rounded-2xl px-3 py-1.5 text-[10px] font-bold transition ${
                    isActive ? "text-wine" : "text-muted"
                  }`}
                >
                  <n.icon size={21} strokeWidth={isActive ? 2.4 : 1.9} />
                  {t.nav[n.labelKey]}
                </span>
              )}
            </NavLink>
          ))}
        </div>
      </nav>
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
    <div className="mb-4 flex flex-wrap items-start justify-between gap-3 sm:mb-6">
      <div>
        <h1 className="text-xl font-extrabold text-ink sm:text-2xl">{title}</h1>
        {subtitle && <p className="mt-1 text-xs text-muted sm:text-sm">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}
