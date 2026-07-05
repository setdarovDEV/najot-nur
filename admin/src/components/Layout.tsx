import { useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import type { ReactNode } from "react";
import {
  LayoutDashboard,
  Users,
  ClipboardList,
  Headphones,
  Bell,
  LogOut,
  CreditCard,
  ShoppingCart,
  Video,
  UserCog,
  ShieldCheck,
  Search,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  MessageCircle,
  Sun,
  Moon,
  Globe,
  Mic,
  Award,
  BookOpen,
  Menu,
  X,
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

const ADMIN_NAV: NavItem[] = [
  { to: "/", labelKey: "dashboard", icon: LayoutDashboard, end: true },
  { to: "/curators", labelKey: "curators", icon: UserCog },
  { to: "/clients", labelKey: "clients", icon: Users },
  { to: "/payments", labelKey: "payments", icon: CreditCard },
  { to: "/orders", labelKey: "orders", icon: ShoppingCart },
  { to: "/audiobooks", labelKey: "audiobooks", icon: Headphones, readOnly: true },
  { to: "/video-lessons", labelKey: "videoLessons", icon: Video, readOnly: true },
  { to: "/notifications", labelKey: "notifications", icon: Bell },
  { to: "/support-chats", labelKey: "supportChats", icon: MessageCircle },
  { to: "/references", labelKey: "references", icon: Mic },
  { to: "/practicums", labelKey: "practicums", icon: Headphones },
  { to: "/quizzes", labelKey: "quizzes", icon: BookOpen },
  { to: "/homeworks", labelKey: "homeworks", icon: ClipboardList },
  { to: "/certificate-requests", labelKey: "certificateRequests", icon: Award },
];

export function Layout() {
  const { logout, user } = useAuth();
  const navigate = useNavigate();
  const { theme, toggle: toggleTheme } = useTheme();
  const { lang, setLang, t } = useLang();
  const [menuOpen, setMenuOpen] = useState(false);
  const [langOpen, setLangOpen] = useState(false);
  // Mobile: drawer open/closed
  const [sidebarOpen, setSidebarOpen] = useState(false);
  // Tablet+PC: icon-only rail (true) vs full sidebar (false)
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const fullName = user?.full_name ?? "Super admin";
  const email = user?.email ?? "admin@najotnur.uz";

  const navItems = (opts: { collapsed: boolean; onNavClick?: () => void }) => (
    <nav className="flex flex-1 flex-col gap-0.5">
      {ADMIN_NAV.map((n) => (
        <NavLink
          key={n.to}
          to={n.to}
          end={n.end}
          title={t.nav[n.labelKey]}
          onClick={opts.onNavClick}
          className={({ isActive }) =>
            `group flex items-center rounded-xl py-2.5 text-sm font-semibold transition ${
              opts.collapsed ? "justify-center px-2" : "gap-3 px-3"
            } ${
              isActive
                ? "bg-white text-wine shadow-md shadow-wine-deep/20"
                : "text-white/85 hover:bg-white/10"
            }`
          }
        >
          <n.icon size={19} strokeWidth={1.75} className="shrink-0" />
          {!opts.collapsed && (
            <>
              <span className="min-w-0 flex-1 truncate">{t.nav[n.labelKey]}</span>
              {n.readOnly && (
                <span className="shrink-0 rounded-full bg-white/20 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide">
                  view
                </span>
              )}
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className="flex min-h-screen bg-surface">

      {/* ── Mobile overlay backdrop ── */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ── Mobile drawer (< md) ── */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex h-full w-72 flex-col overflow-y-auto bg-gradient-to-b from-wine via-wine-dark to-wine-deep p-5 text-white transition-transform duration-300 md:hidden ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        {/* Close button */}
        <button
          onClick={() => setSidebarOpen(false)}
          className="mb-4 self-end rounded-xl border border-white/25 p-2 text-white/80 hover:bg-white/10"
        >
          <X size={18} />
        </button>

        {/* Logo */}
        <div className="mb-8 flex items-center gap-3">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-white/15 text-lg font-black shadow-inner">
            NN
          </div>
          <div>
            <div className="text-lg font-extrabold leading-none tracking-tight">NotiqAI</div>
            <div className="mt-1 flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wider text-white/70">
              <ShieldCheck size={11} />
              {t.sidebar.adminPanel}
            </div>
          </div>
        </div>

        {navItems({ collapsed: false, onNavClick: () => setSidebarOpen(false) })}

        <div className="mt-6 rounded-2xl border border-white/15 bg-white/5 p-4 text-xs text-white/80">
          <div className="mb-1 font-bold text-white">Najot Nur</div>
          <p className="leading-relaxed text-white/65">{t.sidebar.tagline}</p>
        </div>

        <button
          onClick={() => { logout(); navigate("/login"); }}
          className="mt-4 flex items-center gap-3 rounded-xl border border-white/25 px-4 py-3 text-sm font-semibold text-white/90 transition hover:bg-white/10"
        >
          <LogOut size={18} strokeWidth={1.75} />
          {t.sidebar.logout}
        </button>
      </aside>

      {/* ── Tablet + PC sidebar (≥ md) ── */}
      <aside
        className={`sticky top-0 hidden h-screen shrink-0 flex-col overflow-y-auto bg-gradient-to-b from-wine via-wine-dark to-wine-deep py-5 text-white transition-all duration-300 ease-in-out md:flex ${
          sidebarCollapsed ? "w-[60px] px-2" : "w-64 px-4"
        }`}
      >
        {/* Logo */}
        <div
          className={`flex items-center gap-3 transition-all duration-300 ${
            sidebarCollapsed ? "mb-5 justify-center" : "mb-7"
          }`}
        >
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-white/15 text-sm font-black shadow-inner">
            NN
          </div>
          {!sidebarCollapsed && (
            <div className="min-w-0">
              <div className="truncate text-sm font-extrabold leading-none tracking-tight">NotiqAI</div>
              <div className="mt-1 flex items-center gap-1 text-[10px] font-semibold uppercase tracking-wider text-white/70">
                <ShieldCheck size={10} />
                {t.sidebar.adminPanel}
              </div>
            </div>
          )}
        </div>

        {navItems({ collapsed: sidebarCollapsed })}

        {/* Tagline — only expanded */}
        {!sidebarCollapsed && (
          <div className="mt-4 rounded-2xl border border-white/15 bg-white/5 p-3 text-xs text-white/80">
            <div className="mb-1 font-bold text-white">Najot Nur</div>
            <p className="leading-relaxed text-white/65">{t.sidebar.tagline}</p>
          </div>
        )}

        {/* Logout */}
        <button
          onClick={() => { logout(); navigate("/login"); }}
          title={sidebarCollapsed ? t.sidebar.logout : undefined}
          className={`mt-3 flex items-center rounded-xl border border-white/25 py-2.5 text-sm font-semibold text-white/90 transition hover:bg-white/10 ${
            sidebarCollapsed ? "justify-center px-2" : "gap-3 px-3"
          }`}
        >
          <LogOut size={18} strokeWidth={1.75} />
          {!sidebarCollapsed && t.sidebar.logout}
        </button>

        {/* Collapse / expand toggle (inside sidebar) */}
        <button
          onClick={() => setSidebarCollapsed((v) => !v)}
          title={sidebarCollapsed ? "Menuni kengaytirish" : "Menuni yig'ish"}
          className={`mt-2 flex items-center rounded-xl border border-white/20 py-2 text-white/50 transition hover:bg-white/10 hover:text-white/90 ${
            sidebarCollapsed ? "justify-center px-2" : "gap-2 px-3 text-xs font-semibold"
          }`}
        >
          {sidebarCollapsed ? (
            <ChevronRight size={15} />
          ) : (
            <>
              <ChevronLeft size={15} />
              <span>Yig'ish</span>
            </>
          )}
        </button>
      </aside>

      {/* ── Main column ── */}
      <div className="flex min-w-0 flex-1 flex-col">

        {/* Topbar */}
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-line bg-card/80 px-4 backdrop-blur-md md:px-5">

          {/* Mobile hamburger */}
          <button
            onClick={() => setSidebarOpen(true)}
            title="Menuni ochish"
            className="grid h-9 w-9 shrink-0 place-items-center rounded-xl border border-line text-muted transition hover:border-wine/30 hover:text-wine md:hidden"
          >
            <Menu size={20} />
          </button>

          {/* Tablet / PC topbar toggle */}
          <button
            onClick={() => setSidebarCollapsed((v) => !v)}
            title={sidebarCollapsed ? "Menuni ochish" : "Menuni yopish"}
            className="hidden h-9 w-9 shrink-0 place-items-center rounded-xl border border-line text-muted transition hover:border-wine/30 hover:text-wine md:grid"
          >
            {sidebarCollapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
          </button>

          {/* Search */}
          <div className="hidden flex-1 sm:block">
            <div className="relative max-w-md">
              <Search
                size={16}
                className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
              />
              <input
                type="text"
                placeholder={t.topbar.searchAdmin}
                className="w-full rounded-xl border border-line bg-card py-2.5 pl-10 pr-4 text-sm text-ink placeholder:text-muted outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10 dark:bg-[#251d20]"
              />
            </div>
          </div>

          <div className="ml-auto flex items-center gap-2">
            {/* Theme */}
            <button
              onClick={toggleTheme}
              title={theme === "dark" ? "Light mode" : "Dark mode"}
              className="grid h-9 w-9 place-items-center rounded-xl border border-line text-muted transition hover:border-wine/30 hover:text-wine dark:hover:text-white"
            >
              {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
            </button>

            {/* Language */}
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

            <span className="hidden rounded-full bg-wine/10 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-wine dark:bg-wine/15 dark:text-wine-300 sm:inline-flex">
              {t.topbar.admin}
            </span>

            {/* User menu */}
            <div className="relative">
              <button
                onClick={() => { setMenuOpen((v) => !v); setLangOpen(false); }}
                className="flex items-center gap-2.5 rounded-xl border border-line bg-card py-1.5 pl-1.5 pr-3 text-left transition hover:border-wine/30"
              >
                <div className="grid h-8 w-8 place-items-center rounded-lg bg-wine text-xs font-black text-white">
                  SA
                </div>
                <div className="hidden sm:block">
                  <div className="text-sm font-bold leading-none text-ink">{fullName}</div>
                  <div className="mt-0.5 text-[11px] text-muted">{email}</div>
                </div>
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
                      <div className="mt-0.5 text-xs text-muted">{email}</div>
                    </div>
                    <button
                      onClick={() => { setMenuOpen(false); logout(); navigate("/login"); }}
                      className="flex w-full items-center gap-2 px-4 py-3 text-sm font-semibold text-ink hover:bg-wine-50 dark:hover:bg-wine/10"
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

        {/* Page content */}
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
    <div className="mb-4 flex flex-wrap items-start justify-between gap-3 sm:mb-6">
      <div>
        <h1 className="text-xl font-extrabold text-ink sm:text-2xl">{title}</h1>
        {subtitle && <p className="mt-1 text-xs text-muted sm:text-sm">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}
