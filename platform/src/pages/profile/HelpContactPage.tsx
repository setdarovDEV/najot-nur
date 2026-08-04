import { useNavigate } from "react-router-dom";
import { ArrowLeft, Globe, Headset, Instagram, MessageCircle, Phone, Send } from "lucide-react";
import { useLang } from "../../lib/i18n";
import { GlassCard } from "../../components/glass";

export function HelpContactPage() {
  const navigate = useNavigate();
  const { t } = useLang();

  const contacts = [
    { icon: Phone, label: t.support.callUs, value: "+998 71 200 12 34", href: "tel:+998712001234" },
    { icon: Send, label: t.support.telegram, value: "@notiq_ai", href: "https://t.me/notiq_ai" },
    { icon: Instagram, label: t.support.instagram, value: "@notiq_ai", href: "https://instagram.com/notiq_ai" },
    { icon: Globe, label: t.support.website, value: "notiqai.uz", href: "https://notiqai.uz" },
  ];

  return (
    <div className="mx-auto max-w-2xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <div className="flex items-center gap-3">
        <div className="grid h-12 w-12 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
          <Headset size={24} />
        </div>
        <div>
          <h1 className="text-xl font-black text-ink">{t.support.helpTitle}</h1>
          <p className="text-xs text-muted">{t.support.subtitle}</p>
        </div>
      </div>

      <div className="mt-5 space-y-2">
        {contacts.map((c, i) => (
          <a key={i} href={c.href} target="_blank" rel="noreferrer" className="block">
            <GlassCard className="press flex items-center gap-4 p-4 transition hover:shadow-md">
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
                <c.icon size={20} />
              </div>
              <div className="flex-1">
                <div className="text-sm font-bold text-ink">{c.label}</div>
                <div className="mt-0.5 text-xs text-muted">{c.value}</div>
              </div>
            </GlassCard>
          </a>
        ))}
      </div>

      <button
        type="button"
        onClick={() => navigate("/profile/chat")}
        className="press mt-4 flex w-full items-center justify-center gap-2 rounded-full border border-wine/30 bg-wine-50 px-5 py-3 text-sm font-bold text-wine transition hover:bg-wine-100 dark:bg-wine/15 dark:hover:bg-wine/25"
      >
        <MessageCircle size={16} /> {t.profile.supportChat}
      </button>
    </div>
  );
}
