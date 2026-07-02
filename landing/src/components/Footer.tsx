import { Instagram, Mail, MapPin, Phone, Send, Youtube } from "lucide-react";
import Logo from "./Logo";
import { BRAND } from "../lib/config";

export default function Footer() {
  return (
    <footer className="border-t border-wine-100/60 bg-white pb-28 pt-10 md:pb-10">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row md:items-start">
          <div className="text-center md:text-left">
            <Logo />
            <p className="mt-3 max-w-xs text-xs leading-relaxed text-neutral-500">
              Najot Nur notiqlik mahorati markazining AI yordamida nutq tahlili platformasi.
            </p>
          </div>

          <div className="space-y-2.5 text-center text-sm text-neutral-600 md:text-left">
            <a
              href={`tel:${BRAND.contact.phoneRaw}`}
              className="flex items-center justify-center gap-2 font-semibold hover:text-wine-700 md:justify-start"
            >
              <Phone className="h-4 w-4 text-wine-600" /> {BRAND.contact.phone}
            </a>
            <a
              href={`mailto:${BRAND.contact.email}`}
              className="flex items-center justify-center gap-2 font-semibold hover:text-wine-700 md:justify-start"
            >
              <Mail className="h-4 w-4 text-wine-600" /> {BRAND.contact.email}
            </a>
            <p className="flex items-center justify-center gap-2 md:justify-start">
              <MapPin className="h-4 w-4 shrink-0 text-wine-600" /> {BRAND.contact.address}
            </p>
          </div>

          <div className="flex items-center gap-3">
            {[
              { href: BRAND.social.instagram, icon: Instagram, label: "Instagram" },
              { href: BRAND.social.telegram, icon: Send, label: "Telegram" },
              { href: BRAND.social.youtube, icon: Youtube, label: "YouTube" },
            ].map((s) => (
              <a
                key={s.label}
                href={s.href}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={s.label}
                className="flex h-11 w-11 items-center justify-center rounded-2xl bg-wine-50 text-wine-700 transition-colors hover:bg-wine-700 hover:text-white"
              >
                <s.icon className="h-5 w-5" />
              </a>
            ))}
          </div>
        </div>

        <p className="mt-10 border-t border-neutral-100 pt-6 text-center text-xs text-neutral-400">
          © {new Date().getFullYear()} NotiqAI · Najot Nur. Barcha huquqlar himoyalangan.
        </p>
      </div>
    </footer>
  );
}
