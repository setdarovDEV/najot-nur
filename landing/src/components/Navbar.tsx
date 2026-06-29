import { useState } from "react";
import { Menu, X } from "lucide-react";
import { BRAND } from "../lib/config";

const links = [
  { to: "#features", label: "Imkoniyatlar" },
  { to: "#how", label: "Qanday ishlaydi" },
  { to: "#pricing", label: "Narxlar" },
  { to: "#faq", label: "FAQ" },
  { to: "#contact", label: "Bog'lanish" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  return (
    <header className="sticky top-0 z-40 border-b border-line/60 bg-paper/80 backdrop-blur-md">
      <div className="container-x flex h-16 items-center justify-between">
        <a href="#top" className="flex items-center gap-2.5 font-extrabold">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-wine text-white shadow-lg shadow-wine/20">
            NN
          </span>
          <span className="text-lg tracking-tight">
            {BRAND.name}
            <span className="ml-1 text-xs font-semibold text-muted">· {BRAND.parent}</span>
          </span>
        </a>

        <nav className="hidden items-center gap-1 md:flex">
          {links.map((l) => (
            <a
              key={l.to}
              href={l.to}
              className="rounded-lg px-3 py-2 text-sm font-semibold text-ink/80 transition hover:bg-wine-50 hover:text-wine"
            >
              {l.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <a
            href={BRAND.links.curator}
            className="rounded-lg px-4 py-2 text-sm font-semibold text-ink/80 transition hover:bg-wine-50 hover:text-wine"
          >
            Kurator
          </a>
          <a
            href={BRAND.links.admin}
            className="rounded-xl bg-wine px-4 py-2 text-sm font-bold text-white shadow-md shadow-wine/20 transition hover:bg-wine-dark"
          >
            Admin panel
          </a>
        </div>

        <button
          className="grid h-10 w-10 place-items-center rounded-lg text-ink md:hidden"
          onClick={() => setOpen((v) => !v)}
          aria-label="Menyuni ochish"
        >
          {open ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {open && (
        <div className="border-t border-line/60 bg-paper md:hidden">
          <div className="container-x space-y-1 py-4">
            {links.map((l) => (
              <a
                key={l.to}
                href={l.to}
                onClick={() => setOpen(false)}
                className="block rounded-lg px-3 py-2.5 text-sm font-semibold text-ink hover:bg-wine-50 hover:text-wine"
              >
                {l.label}
              </a>
            ))}
            <div className="flex gap-2 pt-2">
              <a
                href={BRAND.links.curator}
                className="flex-1 rounded-xl border border-line px-4 py-2.5 text-center text-sm font-bold text-ink"
              >
                Kurator
              </a>
              <a
                href={BRAND.links.admin}
                className="flex-1 rounded-xl bg-wine px-4 py-2.5 text-center text-sm font-bold text-white"
              >
                Admin panel
              </a>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
