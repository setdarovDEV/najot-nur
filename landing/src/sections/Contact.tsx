import { useState, type FormEvent } from "react";
import { Mail, Phone, MapPin, Send, CheckCircle2, Clock } from "lucide-react";
import { BRAND } from "../lib/config";
import { useReveal } from "../lib/hooks";

export function Contact() {
  const [form, setForm] = useState({ name: "", email: "", message: "" });
  const [sent, setSent] = useState(false);
  const { ref, visible } = useReveal<HTMLDivElement>();

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!form.name || !form.email || !form.message) return;
    setSent(true);
    setForm({ name: "", email: "", message: "" });
    window.setTimeout(() => setSent(false), 4000);
  }

  return (
    <section id="contact" className="bg-paper py-20 md:py-28">
      <div className="container-x">
        <div ref={ref} className={`reveal ${visible ? "is-visible" : ""}`}>
          <div className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-bold uppercase tracking-wider text-wine">
              Bog'lanish
            </span>
            <h2 className="mt-3 text-4xl font-extrabold md:text-5xl">
              Savol bormi? Yozing
            </h2>
            <p className="mt-4 text-lg text-muted">
              24 soat ichida javob beramiz. Yoki quyidagi kontaktlarga murojaat qiling.
            </p>
          </div>

          <div className="mt-14 grid gap-8 lg:grid-cols-2">
            <div className="space-y-4">
              <ContactItem
                icon={<Mail size={18} />}
                label="Email"
                value={BRAND.contact.email}
                href={`mailto:${BRAND.contact.email}`}
                delay={0}
              />
              <ContactItem
                icon={<Phone size={18} />}
                label="Telefon"
                value={BRAND.contact.phone}
                href={`tel:${BRAND.contact.phoneRaw}`}
                delay={80}
              />
              <ContactItem
                icon={<MapPin size={18} />}
                label="Manzil"
                value={BRAND.contact.address}
                href="https://yandex.uz/maps/org/najot_nur_notiqlik_markazi/92426418091/"
                delay={160}
              />
              <ContactItem
                icon={<Clock size={18} />}
                label="Ish vaqti"
                value={BRAND.contact.workHours}
                href="#"
                delay={240}
              />
            </div>

            <form
              onSubmit={onSubmit}
              className="rounded-2xl border border-line bg-white p-6 shadow-sm transition hover:shadow-lg hover:shadow-wine/5 md:p-8"
            >
              <div className="space-y-4">
                <Field
                  label="Ism"
                  value={form.name}
                  onChange={(v) => setForm((f) => ({ ...f, name: v }))}
                  placeholder="Ismingiz"
                  required
                />
                <Field
                  label="Email"
                  type="email"
                  value={form.email}
                  onChange={(v) => setForm((f) => ({ ...f, email: v }))}
                  placeholder="name@example.com"
                  required
                />
                <div>
                  <label className="mb-1.5 block text-sm font-semibold text-ink">
                    Xabar
                  </label>
                  <textarea
                    rows={4}
                    required
                    value={form.message}
                    onChange={(e) => setForm((f) => ({ ...f, message: e.target.value }))}
                    className="w-full rounded-xl border border-line bg-paper px-4 py-3 text-sm text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/15"
                    placeholder="Xabaringizni yozing…"
                  />
                </div>
                <button
                  type="submit"
                  className="group relative inline-flex w-full items-center justify-center gap-2 overflow-hidden rounded-xl bg-wine px-5 py-3 text-sm font-bold text-white transition hover:bg-wine-dark"
                >
                  <span className="relative z-10 flex items-center gap-2">
                    <Send size={15} />
                    Yuborish
                  </span>
                  <span
                    aria-hidden
                    className="absolute inset-0 -translate-x-full bg-gradient-to-r from-wine-dark via-orange to-wine-dark transition-transform duration-700 group-hover:translate-x-0"
                  />
                </button>
                {sent && (
                  <div
                    className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-2.5 text-sm font-semibold text-green-700"
                    style={{ animation: "fade-up 0.5s ease-out both" }}
                  >
                    <CheckCircle2 size={16} />
                    Xabaringiz qabul qilindi. Tez orada bog'lanamiz.
                  </div>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
}

function ContactItem({
  icon, label, value, href, delay = 0,
}: { icon: React.ReactNode; label: string; value: string; href: string; delay?: number }) {
  return (
    <a
      href={href}
      target={href.startsWith("http") ? "_blank" : undefined}
      rel={href.startsWith("http") ? "noreferrer noopener" : undefined}
      className="group flex items-center gap-4 rounded-2xl border border-line bg-white p-5 transition hover:-translate-y-0.5 hover:border-wine/30 hover:shadow-md hover:shadow-wine/5"
      style={{ animation: `fade-up 0.6s ${delay}ms ease-out both` }}
    >
      <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-wine/10 text-wine transition group-hover:scale-110 group-hover:bg-wine group-hover:text-white">
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-xs font-bold uppercase tracking-wider text-muted">
          {label}
        </div>
        <div className="mt-0.5 truncate text-sm font-bold text-ink">{value}</div>
      </div>
    </a>
  );
}

function Field({
  label, value, onChange, placeholder, type = "text", required,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-ink">
        {label}
      </label>
      <input
        type={type}
        required={required}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-line bg-paper px-4 py-3 text-sm text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/15"
        placeholder={placeholder}
      />
    </div>
  );
}
