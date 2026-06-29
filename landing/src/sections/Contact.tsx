import { useState, type FormEvent } from "react";
import { Mail, Phone, MapPin, Send, CheckCircle2 } from "lucide-react";
import { BRAND } from "../lib/config";

export function Contact() {
  const [form, setForm] = useState({ name: "", email: "", message: "" });
  const [sent, setSent] = useState(false);

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
            <ContactItem icon={<Mail size={18} />} label="Email" value={BRAND.contact.email} href={`mailto:${BRAND.contact.email}`} />
            <ContactItem icon={<Phone size={18} />} label="Telefon" value={BRAND.contact.phone} href={`tel:${BRAND.contact.phone.replace(/\s/g, "")}`} />
            <ContactItem icon={<MapPin size={18} />} label="Manzil" value={BRAND.contact.address} href="#" />
          </div>

          <form
            onSubmit={onSubmit}
            className="rounded-2xl border border-line bg-white p-6 shadow-sm md:p-8"
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
                className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-wine px-5 py-3 text-sm font-bold text-white transition hover:bg-wine-dark"
              >
                <Send size={15} />
                Yuborish
              </button>
              {sent && (
                <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-2.5 text-sm font-semibold text-green-700">
                  <CheckCircle2 size={16} />
                  Xabaringiz qabul qilindi. Tez orada bog'lanamiz.
                </div>
              )}
            </div>
          </form>
        </div>
      </div>
    </section>
  );
}

function ContactItem({
  icon, label, value, href,
}: { icon: React.ReactNode; label: string; value: string; href: string }) {
  return (
    <a
      href={href}
      className="flex items-center gap-4 rounded-2xl border border-line bg-white p-5 transition hover:border-wine/30 hover:shadow-md hover:shadow-wine/5"
    >
      <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-wine/10 text-wine">
        {icon}
      </div>
      <div>
        <div className="text-xs font-bold uppercase tracking-wider text-muted">
          {label}
        </div>
        <div className="mt-0.5 text-sm font-bold text-ink">{value}</div>
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
