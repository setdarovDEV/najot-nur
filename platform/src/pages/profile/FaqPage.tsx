import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, ChevronDown, MessageCircle } from "lucide-react";
import { useLang } from "../../lib/i18n";
import { GlassCard, PrimaryButton } from "../../components/glass";

export function FaqPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const [openIdx, setOpenIdx] = useState<number | null>(0);

  const faqs: { q: string; a: string }[] = [
    { q: t.support.faqTitle, a: t.support.chatSubtitle },
    { q: t.certificates.subtitle, a: t.certificates.requestHint },
    { q: t.courses.notEnrolled, a: t.orders.requestDesc },
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
      <h1 className="text-xl font-black text-ink">{t.profile.faq}</h1>

      <div className="mt-5 space-y-2">
        {faqs.map((f, i) => (
          <GlassCard key={i}>
            <button
              type="button"
              onClick={() => setOpenIdx(openIdx === i ? null : i)}
              className="flex w-full items-center gap-3 p-4 text-left"
            >
              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-wine-50 text-wine dark:bg-wine/20">
                <MessageCircle size={16} />
              </div>
              <span className="flex-1 text-sm font-bold text-ink">{f.q}</span>
              <ChevronDown
                size={16}
                className={`shrink-0 text-muted transition ${openIdx === i ? "rotate-180" : ""}`}
              />
            </button>
            {openIdx === i && (
              <p className="border-t border-line px-4 pb-4 pt-3 text-sm leading-relaxed text-muted">
                {f.a}
              </p>
            )}
          </GlassCard>
        ))}
      </div>

      <PrimaryButton onClick={() => navigate("/profile/chat")} className="mt-5 w-full">
        <MessageCircle size={15} /> {t.profile.supportChat}
      </PrimaryButton>
    </div>
  );
}
