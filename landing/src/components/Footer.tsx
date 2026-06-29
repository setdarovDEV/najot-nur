import { Send, Globe, AtSign, Play } from "lucide-react";
import { BRAND } from "../lib/config";

const sections = [
  {
    title: "Mahsulot",
    items: [
      { label: "Imkoniyatlar", href: "#features" },
      { label: "Qanday ishlaydi", href: "#how" },
      { label: "Narxlar", href: "#pricing" },
      { label: "FAQ", href: "#faq" },
    ],
  },
  {
    title: "Platformalar",
    items: [
      { label: "Admin panel", href: BRAND.links.admin },
      { label: "Kurator paneli", href: BRAND.links.curator },
      { label: "API hujjati", href: BRAND.links.api },
    ],
  },
  {
    title: "Bog'lanish",
    items: [
      { label: BRAND.contact.email, href: `mailto:${BRAND.contact.email}` },
      { label: BRAND.contact.phone, href: `tel:${BRAND.contact.phone.replace(/\s/g, "")}` },
      { label: BRAND.contact.address, href: "#contact" },
    ],
  },
];

export function Footer() {
  return (
    <footer className="border-t border-line bg-white">
      <div className="container-x grid gap-10 py-14 md:grid-cols-4">
        <div>
          <a href="#top" className="flex items-center gap-2.5 font-extrabold">
            <span className="grid h-9 w-9 place-items-center rounded-xl bg-wine text-white">NN</span>
            <span className="text-lg">{BRAND.name}</span>
          </a>
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted">
            {BRAND.description}
          </p>
          <div className="mt-5 flex gap-2">
            <SocialIcon href={BRAND.social.telegram} label="Telegram">
              <Send size={16} />
            </SocialIcon>
            <SocialIcon href={BRAND.social.instagram} label="Instagram">
              <AtSign size={16} />
            </SocialIcon>
            <SocialIcon href={BRAND.social.youtube} label="YouTube">
              <Play size={16} />
            </SocialIcon>
            <SocialIcon href={BRAND.social.facebook} label="Facebook">
              <Globe size={16} />
            </SocialIcon>
          </div>
        </div>

        {sections.map((s) => (
          <div key={s.title}>
            <div className="text-xs font-bold uppercase tracking-wider text-wine">
              {s.title}
            </div>
            <ul className="mt-4 space-y-2.5">
              {s.items.map((i) => (
                <li key={i.label}>
                  <a
                    href={i.href}
                    className="text-sm text-ink/80 transition hover:text-wine"
                  >
                    {i.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="border-t border-line">
        <div className="container-x flex flex-col items-center justify-between gap-2 py-5 text-xs text-muted md:flex-row">
          <p>© {new Date().getFullYear()} {BRAND.name} · {BRAND.parent}. Barcha huquqlar himoyalangan.</p>
          <p>
            <a href={BRAND.parentUrl} className="font-semibold text-wine hover:underline">
              {BRAND.parent}
            </a>{" "}
            tomonidan ishlab chiqilgan
          </p>
        </div>
      </div>
    </footer>
  );
}

function SocialIcon({ href, label, children }: { href: string; label: string; children: React.ReactNode }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer noopener"
      aria-label={label}
      className="grid h-9 w-9 place-items-center rounded-lg border border-line text-ink/70 transition hover:border-wine/30 hover:bg-wine-50 hover:text-wine"
    >
      {children}
    </a>
  );
}
