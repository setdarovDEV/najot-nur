import {
  Send, AtSign, Play, Globe, Sparkles, ArrowUpRight, Mail, Phone, MapPin,
} from "lucide-react";
import { BRAND } from "../lib/config";
import { QRPlaceholder } from "./QRPlaceholder";

const productLinks = [
  { label: "Imkoniyatlar", href: "#features" },
  { label: "Qanday ishlaydi", href: "#how" },
  { label: "Narxlar", href: "#pricing" },
  { label: "FAQ", href: "#faq" },
  { label: "Biz haqimizda", href: "#about" },
];

const platformLinks = [
  { label: "Admin panel", href: BRAND.links.admin },
  { label: "Kurator paneli", href: BRAND.links.curator },
  { label: "API hujjati", href: BRAND.links.api },
  { label: "najotnur.uz", href: BRAND.parentUrl },
];

const contactItems = [
  { icon: <Mail size={14} />, label: BRAND.contact.email, href: `mailto:${BRAND.contact.email}` },
  { icon: <Phone size={14} />, label: BRAND.contact.phone, href: `tel:${BRAND.contact.phoneRaw}` },
  { icon: <MapPin size={14} />, label: "Toshkent, Sharq Tongi 9A", href: "https://yandex.uz/maps/org/najot_nur_notiqlik_markazi/92426418091/" },
];

const socialLinks = [
  { icon: <Send size={16} />, label: "Telegram", href: BRAND.social.telegram, color: "hover:bg-sky-500/10 hover:text-sky-500" },
  { icon: <AtSign size={16} />, label: "Instagram", href: BRAND.social.instagram, color: "hover:bg-pink-500/10 hover:text-pink-500" },
  { icon: <Play size={16} />, label: "YouTube", href: BRAND.social.youtube, color: "hover:bg-red-500/10 hover:text-red-500" },
  { icon: <Globe size={16} />, label: "Facebook", href: BRAND.social.facebook, color: "hover:bg-blue-500/10 hover:text-blue-500" },
];

const marqueeItems = [
  "Notiqlik san'ati",
  "Sun'iy intellekt",
  "5,300+ bitiruvchi",
  "12+ filial",
  "24 kurs",
  "18 kurator",
  "AUDIONOMA",
  "Toshkent · Samarqand · Buxoro",
];

export function Footer() {
  return (
    <footer className="relative overflow-hidden border-t border-line bg-white">
      <div
        aria-hidden
        className="absolute -left-32 top-20 h-80 w-80 animate-blob rounded-full bg-wine/5 blur-3xl"
      />
      <div
        aria-hidden
        className="absolute -right-32 bottom-20 h-80 w-80 animate-blob rounded-full bg-orange/5 blur-3xl"
        style={{ animationDelay: "3s" }}
      />

      <div
        aria-hidden
        className="group relative overflow-hidden border-b border-line bg-gradient-to-r from-wine via-wine-dark to-wine py-3 text-white"
      >
        <div className="flex w-max animate-marquee gap-10 whitespace-nowrap pl-10">
          {[...marqueeItems, ...marqueeItems].map((item, i) => (
            <div key={i} className="flex items-center gap-3 text-sm font-semibold">
              <Sparkles size={12} className="text-orange" />
              <span>{item}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="container-x relative grid gap-12 py-16 md:grid-cols-12">
        <div className="md:col-span-4">
          <a href="#top" className="group inline-flex items-center gap-2.5 font-extrabold">
            <span className="relative grid h-10 w-10 place-items-center overflow-hidden rounded-xl bg-wine text-white shadow-lg shadow-wine/25 transition group-hover:scale-105 group-hover:rotate-3">
              <span className="relative z-10">NN</span>
              <span
                aria-hidden
                className="absolute inset-0 bg-gradient-to-br from-wine via-orange to-skyblue opacity-0 transition group-hover:opacity-100"
              />
            </span>
            <span className="text-lg">
              {BRAND.name}
              <span className="ml-1 text-xs font-semibold text-muted">· {BRAND.parent}</span>
            </span>
          </a>
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted">
            {BRAND.description}
          </p>

          <div className="mt-5 space-y-2 text-xs text-muted">
            {contactItems.map((c) => (
              <a
                key={c.label}
                href={c.href}
                target={c.href.startsWith("http") ? "_blank" : undefined}
                rel={c.href.startsWith("http") ? "noreferrer noopener" : undefined}
                className="group flex items-center gap-2 font-semibold text-ink/80 transition hover:text-wine"
              >
                <span className="text-wine transition group-hover:scale-110">{c.icon}</span>
                <span className="truncate">{c.label}</span>
              </a>
            ))}
          </div>

          <div className="mt-5 flex flex-wrap gap-2">
            {socialLinks.map((s) => (
              <a
                key={s.label}
                href={s.href}
                target="_blank"
                rel="noreferrer noopener"
                aria-label={s.label}
                className={`group grid h-10 w-10 place-items-center rounded-xl border border-line text-ink/70 transition hover:scale-110 hover:border-current ${s.color}`}
              >
                {s.icon}
              </a>
            ))}
          </div>
        </div>

        <div className="md:col-span-2">
          <FooterTitle>Mahsulot</FooterTitle>
          <ul className="mt-4 space-y-2.5">
            {productLinks.map((i) => (
              <li key={i.label}>
                <a
                  href={i.href}
                  className="group inline-flex items-center gap-1 text-sm text-ink/80 transition hover:text-wine"
                >
                  {i.label}
                  <ArrowUpRight
                    size={11}
                    className="opacity-0 transition group-hover:opacity-100 group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
                  />
                </a>
              </li>
            ))}
          </ul>
        </div>

        <div className="md:col-span-2">
          <FooterTitle>Platformalar</FooterTitle>
          <ul className="mt-4 space-y-2.5">
            {platformLinks.map((i) => (
              <li key={i.label}>
                <a
                  href={i.href}
                  target={i.href.startsWith("http") ? "_blank" : undefined}
                  rel={i.href.startsWith("http") ? "noreferrer noopener" : undefined}
                  className="group inline-flex items-center gap-1 text-sm text-ink/80 transition hover:text-wine"
                >
                  {i.label}
                  <ArrowUpRight
                    size={11}
                    className="opacity-0 transition group-hover:opacity-100 group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
                  />
                </a>
              </li>
            ))}
          </ul>
        </div>

        <div className="md:col-span-4">
          <FooterTitle>Ilovani yuklab oling</FooterTitle>
          <p className="mt-3 text-xs leading-relaxed text-muted">
            QR kodni skaner qilib iOS yoki Android uchun NotiqAI ilovasini o'rnating.
            Demo-versiya — tez orada rasmiy reliz.
          </p>
          <div className="mt-4 flex flex-row flex-wrap items-center gap-3">
            <QRPlaceholder
              label="Google Play"
              store="play"
              href={BRAND.links.playMarket}
              size={120}
            />
            <QRPlaceholder
              label="App Store"
              store="ios"
              href={BRAND.links.appStore}
              size={120}
            />
          </div>
        </div>
      </div>

      <div className="border-t border-line bg-paper/60">
        <div className="container-x flex flex-col items-center justify-between gap-3 py-5 text-xs text-muted md:flex-row">
          <p>
            © {new Date().getFullYear()} {BRAND.name} ·{" "}
            <a
              href={BRAND.parentUrl}
              target="_blank"
              rel="noreferrer noopener"
              className="font-semibold text-wine transition hover:underline"
            >
              {BRAND.parent}
            </a>{" "}
            notiqlik markazi tomonidan ishlab chiqilgan. Barcha huquqlar himoyalangan.
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <a
              href={BRAND.social.telegramAdmin}
              target="_blank"
              rel="noreferrer noopener"
              className="inline-flex items-center gap-1.5 font-semibold text-ink/70 transition hover:text-wine"
            >
              <Send size={12} />
              Admin bilan bog'lanish
            </a>
            <span aria-hidden className="h-3 w-px bg-line" />
            <a
              href={`tel:${BRAND.contact.phoneRaw}`}
              className="inline-flex items-center gap-1.5 font-semibold text-ink/70 transition hover:text-wine"
            >
              <Phone size={12} />
              {BRAND.contact.phone}
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}

function FooterTitle({ children }: { children: React.ReactNode }) {
  return (
    <div className="text-xs font-bold uppercase tracking-wider text-wine">
      {children}
    </div>
  );
}
