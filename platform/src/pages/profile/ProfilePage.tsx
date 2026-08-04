import { Link, useNavigate } from "react-router-dom";
import {
  Award,
  Bell,
  ChevronRight,
  FileClock,
  Globe,
  Headset,
  HelpCircle,
  LogOut,
  MessageCircle,
  Moon,
  Pencil,
  Phone,
  ShoppingCart,
  Sun,
} from "lucide-react";
import { useAuth } from "../../lib/auth";
import { useTheme } from "../../lib/theme";
import { useLang } from "../../lib/i18n";
import { GlassCard, Reveal } from "../../components/glass";
import { useConfirm } from "../../lib/confirm";

export function ProfilePage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { t } = useLang();
  const { theme, toggle } = useTheme();
  const confirm = useConfirm();

  const fullName = user?.full_name ?? t.profile.guest;

  const items = [
    { to: "/profile/edit", icon: Pencil, label: t.profile.edit },
    { to: "/profile/orders", icon: ShoppingCart, label: t.profile.myOrders },
    { to: "/profile/certificates", icon: Award, label: t.profile.myCertificates },
    { to: "/profile/history", icon: FileClock, label: t.profile.myHistory },
    { to: "/profile/notifications", icon: Bell, label: t.profile.notifications },
    { to: "/profile/chat", icon: MessageCircle, label: t.profile.supportChat },
    { to: "/profile/faq", icon: HelpCircle, label: t.profile.faq },
    { to: "/profile/help", icon: Headset, label: t.profile.helpContact },
  ];

  async function onLogout() {
    const ok = await confirm({
      title: t.profile.logout,
      description: t.auth.loggedOut,
      confirmText: t.profile.logout,
      variant: "danger",
    });
    if (!ok) return;
    logout();
    navigate("/login");
  }

  return (
    <div className="mx-auto max-w-2xl">
      {/* Header card */}
      <Reveal>
        <GlassCard className="overflow-hidden">
          <div className="h-20 bg-gradient-to-r from-wine via-wine-dark to-wine-deep" />
          <div className="flex flex-col items-center px-5 pb-5 sm:flex-row sm:items-end sm:gap-4">
            <div className="-mt-10 grid h-20 w-20 shrink-0 place-items-center rounded-full border-4 border-card bg-wine text-xl font-black text-white shadow-xl">
              {(fullName.match(/\b\w/g) ?? ["N"]).slice(0, 2).join("").toUpperCase()}
            </div>
            <div className="mt-3 flex-1 text-center sm:mt-0 sm:text-left">
              <h1 className="text-lg font-black text-ink">{fullName}</h1>
              <div className="mt-1 flex flex-wrap items-center justify-center gap-2 text-xs text-muted sm:justify-start">
                {user?.phone && (
                  <span className="flex items-center gap-1"><Phone size={12} /> {user.phone}</span>
                )}
                {user?.city && (
                  <span className="flex items-center gap-1"><Globe size={12} /> {user.city}</span>
                )}
              </div>
            </div>
            <Link
              to="/profile/edit"
              className="press mt-3 flex shrink-0 items-center gap-2 rounded-full border border-line bg-card px-4 py-2 text-xs font-bold text-ink transition hover:border-wine/40 sm:mt-0"
            >
              <Pencil size={14} className="text-wine" /> {t.profile.edit}
            </Link>
          </div>
        </GlassCard>
      </Reveal>

      {/* Language / theme */}
      <Reveal index={1}>
        <div className="mt-4 grid grid-cols-2 gap-3">
          <GlassCard className="flex items-center justify-between p-4">
            <span className="flex items-center gap-2 text-sm font-bold text-ink">
              <Globe size={16} className="text-wine" /> {t.profile.language}
            </span>
            <LanguageSelector />
          </GlassCard>
          <GlassCard className="flex items-center justify-between p-4">
            <span className="flex items-center gap-2 text-sm font-bold text-ink">
              {theme === "dark" ? <Moon size={16} className="text-wine" /> : <Sun size={16} className="text-wine" />}
              {t.profile.theme}
            </span>
            <button
              type="button"
              onClick={toggle}
              className="press grid h-8 w-8 place-items-center rounded-full border border-line text-muted transition hover:text-wine"
              aria-label="Toggle theme"
            >
              {theme === "dark" ? <Sun size={15} /> : <Moon size={15} />}
            </button>
          </GlassCard>
        </div>
      </Reveal>

      {/* Menu */}
      <Reveal index={2}>
        <div className="mt-4 space-y-2">
          {items.map((item) => (
            <Link key={item.to} to={item.to}>
              <GlassCard className="press flex items-center gap-3 p-4 transition hover:shadow-md">
                <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
                  <item.icon size={18} />
                </div>
                <span className="flex-1 text-sm font-bold text-ink">{item.label}</span>
                <ChevronRight size={16} className="shrink-0 text-muted" />
              </GlassCard>
            </Link>
          ))}
        </div>
      </Reveal>

      <Reveal index={3}>
        <button
          type="button"
          onClick={onLogout}
          className="press mt-4 flex w-full items-center justify-center gap-2 rounded-full border border-red-200 bg-red-50 px-5 py-3.5 text-sm font-bold text-red-600 transition hover:bg-red-100 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30"
        >
          <LogOut size={16} /> {t.profile.logout}
        </button>
      </Reveal>
    </div>
  );
}

function LanguageSelector() {
  const { lang, setLang } = useLang();
  const { t } = useLang();
  return (
    <select
      value={lang}
      onChange={(e) => setLang(e.target.value as "uz" | "ru" | "en")}
      className="rounded-full border border-line bg-card px-3 py-1.5 text-xs font-bold text-ink focus:border-wine focus:outline-none"
      aria-label={t.profile.language}
    >
      <option value="uz">Oʻzbekcha</option>
      <option value="ru">Русский</option>
      <option value="en">English</option>
    </select>
  );
}
